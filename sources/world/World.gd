extends Node2D

# Types
class Instance extends SubViewport:
	var id : int							= 0
	var npcs : Array[BaseAgent]				= []
	var mobs : Array[BaseAgent]				= []
	var players : Array[BaseAgent]			= []

class Map:
	var name : String						= ""
	var instances : Array[Instance]			= []
	var spawns : Array[SpawnObject]			= []
	var warps : Array[WarpObject]			= []
	var nav_poly : NavigationPolygon		= null
	var mapRID : RID						= RID()
	var regionRID : RID						= RID()

# Vars
var areas : Dictionary = {}
var rids : Dictionary = {}

# Utils
func GetRandomPosition(map : Map) -> Vector2i:
	Launcher.Util.Assert(map != null && map.nav_poly != null && map.nav_poly.get_polygon_count() > 0, "No triangulation available")
	if map != null && map.nav_poly != null && map.nav_poly.get_polygon_count() > 0:
		var outlinesList : PackedVector2Array  = map.nav_poly.get_vertices()

		var randPolygonID : int = randi_range(0, map.nav_poly.get_polygon_count() - 1)
		var randPolygon : PackedInt32Array = map.nav_poly.get_polygon(randPolygonID)

		var randVerticeID : int = randi_range(0, randPolygon.size() - 1)
		var a : Vector2 = outlinesList[randPolygon[randVerticeID]]
		var b : Vector2 = outlinesList[randPolygon[(randVerticeID + 1) % randPolygon.size()]]
		var c : Vector2 = outlinesList[randPolygon[(randVerticeID + 2) % randPolygon.size()]]

		return Vector2i(a + sqrt(randf()) * (-a + b + randf() * (c - b)))

	Launcher.Util.Assert(false, "Mob could not be spawned, no available point on the navigation mesh were found")
	return Vector2i.ZERO

func GetRandomPositionAABB(map : Map, pos : Vector2i, offset : Vector2i) -> Vector2i:
	Launcher.Util.Assert(map != null, "Could not create a random position for a non-initialized map")
	if map != null:
		for i in Launcher.Conf.GetInt("Navigation", "navigationSpawnTry", Launcher.Conf.Type.SERVER):
			var randPoint : Vector2i = Vector2i(randi_range(-offset.x, offset.x), randi_range(-offset.y, offset.y))
			randPoint += pos

			var closestPoint : Vector2i = NavigationServer2D.map_get_closest_point(map.mapRID, randPoint)
			if randPoint == closestPoint:
				return randPoint

	return GetRandomPosition(map)

# Instance init
func LoadMapData(mapName : String, ext : String) -> Object:
	var mapPath : String			= Launcher.DB.GetMapPath(mapName)
	var mapInstance : Object		= Launcher.FileSystem.LoadMap(mapPath, ext)

	return mapInstance

func LoadGenericData(map : Map):
	var node : Node = LoadMapData(map.name, Launcher.Path.MapServerExt)
	if node:
		if "spawns" in node:
			for spawn in node.spawns:
				Launcher.Util.Assert(spawn != null, "Warp format is not supported")
				if spawn:
					var spawnObject = SpawnObject.new()
					spawnObject.count = spawn[0]
					spawnObject.name = spawn[1]
					spawnObject.type = spawn[2]
					spawnObject.spawn_position = spawn[3]
					spawnObject.spawn_offset = spawn[4]
					spawnObject.is_global = spawnObject.spawn_position < Vector2i.LEFT
					map.spawns.append(spawnObject)
		if "warps" in node:
			for warp in node.warps:
				Launcher.Util.Assert(warp != null, "Warp format is not supported")
				if warp:
					var warpObject = WarpObject.new()
					warpObject.destinationMap = warp[0]
					warpObject.destinationPos = warp[1]
					warpObject.polygon = warp[2]
					map.warps.append(warpObject)

func LoadNavigationData(map : Map):
	var obj : Object = LoadMapData(map.name, Launcher.Path.MapNavigationExt)
	if obj:
		map.nav_poly = obj

func CreateNavigation(map : Map, mapRID : RID):
	if map.nav_poly:
		map.mapRID = mapRID if mapRID.is_valid() else NavigationServer2D.map_create()
		NavigationServer2D.map_set_active(map.mapRID, true)
		NavigationServer2D.map_set_cell_size(map.mapRID, 0.1)

		map.regionRID = NavigationServer2D.region_create()
		NavigationServer2D.region_set_map(map.regionRID, map.mapRID)
		NavigationServer2D.region_set_navigation_polygon(map.regionRID, map.nav_poly)

		NavigationServer2D.map_force_update(map.mapRID)

func CreateInstance(map : Map, instanceID : int = 0):
	var inst : Instance = Instance.new()
	CreateNavigation(map, inst.get_world_2d().get_navigation_map())

	inst.id = instanceID
	for spawn in map.spawns:
		for i in spawn.count:
			var agent : BaseAgent = Launcher.DB.Instantiate.CreateAgent(spawn.type, spawn.name)
			rids[agent.get_rid().get_id()] = agent

			Launcher.Util.Assert(agent != null, "Agent %s (type: %s) could not be created" % [spawn.name, spawn.type])
			if agent:
				if spawn.is_global:
					agent.position = GetRandomPosition(map)
				else:
					agent.position = GetRandomPositionAABB(map, spawn.spawn_position, spawn.spawn_offset)

				# TODO: use internal Spawn function
				Launcher.Util.Assert(agent.position != Vector2.ZERO, "Could not spawn the agent %s, no walkable position found" % spawn.name)
				if agent.position != Vector2.ZERO:
					match spawn.type:
						"Player":	inst.players.append(agent)
						"Npc":		inst.npcs.append(agent)
						"Monster":	inst.mobs.append(agent)
						"Trigger":	inst.npcs.append(agent)
						_: Launcher.Util.Assert(false, "Agent type is not valid")
					inst.add_child(agent)

	for agent in inst.npcs + inst.players + inst.mobs:
		if agent.agent:
			agent.agent.set_navigation_map(map.mapRID)

	inst.disable_3d = true
	inst.gui_disable_input = true
	inst.name = map.name
	if instanceID > 0:
		inst.name += "_" + str(instanceID)

	Launcher.Root.add_child(inst)
	map.instances.push_back(inst)

# Agent Management
func Warp(entityName : String, oldMap : String, newMap : String, newPos : Vector2i):
	var bOK : bool = areas.has(oldMap)
	Launcher.Util.Assert(bOK, "Warp could not proceed, previous map not found")

	if bOK:
		bOK = false

		for instance in areas[oldMap].instances:
			var agent : BaseAgent = null
			for playerAgent in instance.players:
				if playerAgent && playerAgent.agentName == entityName:
					agent = playerAgent
					break

			if agent:
				var arrayIdx : int = instance.players.find(agent)
				if arrayIdx >= 0:
					instance.players.remove_at(arrayIdx)
					instance.remove_child(agent)
					Spawn(newMap, agent)
					agent.set_position(newPos)
					agent.ResetNav()
					bOK = true

	Launcher.Util.Assert(bOK, "Warp could not proceed, the agent is not found on old map's instances")

func Spawn(newMap : String, agent : Node2D, instID : int = 0):
	var err : bool = false
	err = err || not areas.has(newMap)
	err = err || agent == null
	Launcher.Util.Assert(not err, "Warp could not proceed, one or multiple parameters are invalid")

	if not err:
		if agent.agent:
			agent.agent.set_navigation_map(areas[newMap].mapRID)

		var inst : Instance = areas[newMap].instances[instID]
		var arrayIdx : int = inst.players.find(agent)
		if arrayIdx < 0:
			inst.players.push_back(agent)
			inst.add_child(agent)
		else:
			err = true

	Launcher.Util.Assert(not err, "Warp could not proceed, the agent is not found on new map's instances")

func GetAgents(mapName : String, playerName : String):
	var list : Array = []
	var area : Map = areas[mapName] if areas.has(mapName) else null
	Launcher.Util.Assert(area != null, "World can't find the map name " + mapName)
	if area:
		for instance in area.instances:
			for player in instance.players:
				if player.agentName == playerName:
					list = instance.npcs + instance.mobs + instance.players
					break
	return list

func HasAgent(agentName : String, checkPlayers = true, checkNpcs = true, checkMonsters = true):
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for agent in \
				instance.players if checkPlayers else [] + \
				instance.npcs if checkNpcs else [] + \
				instance.mobs if checkMonsters else []:
					if agent.agentName == agentName:
						return true
	return false

func RemoveAgent(agentName : String, checkPlayers = true, checkNpcs = true, checkMonsters = true):
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for agent in instance.players:
					if agent.agentName == agentName:
						instance.players.erase(agent)
			if checkNpcs:
				for agent in instance.npcs:
					if agent.agentName == agentName:
						instance.npcs.erase(agent)
			if checkMonsters:
				for agent in instance.mobs:
					if agent.agentName == agentName:
						instance.mobs.erase(agent)

# AI
func UpdateWalkPaths(agent : Node2D, map : Map):
	var randAABB : Vector2i = Vector2i(randi_range(30, 200), randi_range(30, 200))
	var newPos : Vector2i = GetRandomPositionAABB(map, agent.position, randAABB)
	agent.WalkToward(newPos)

func UpdateAI(agent : BaseAgent, map : Map):
	if agent.hasCurrentGoal == false && agent.aiTimer && agent.aiTimer.is_stopped():
		agent.aiTimer.StartTimer(randf_range(5, 15), UpdateWalkPaths.bind(agent, map))
	elif agent.hasCurrentGoal && agent.IsStuck():
		agent.ResetNav()
		agent.aiTimer.StartTimer(randf_range(2, 10), UpdateWalkPaths.bind(agent, map))
	agent.UpdateInput()

# Generic
func _post_launch():
	for mapName in Launcher.DB.MapsDB:
		var map : Map = Map.new()
		map.name = mapName
		LoadGenericData(map)
		LoadNavigationData(map)
		CreateInstance(map)
		areas[mapName] = map

func _process(_dt : float):
	for map in areas.values():
		for instance in map.instances:
			if Launcher.Debug or instance.players.size() > 0:
				for agent in instance.npcs + instance.mobs:
					UpdateAI(agent, map)
				for player in instance.players:
					var playerID : int = Launcher.Network.Server.playerMap.find_key(player.get_rid().get_id())
					for agent in instance.npcs + instance.mobs:
						Launcher.Network.Server.UpdateEntity(playerID, agent.get_rid().get_id(), agent.currentVelocity, agent.position)
