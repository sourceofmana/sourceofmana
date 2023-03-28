extends Node2D

# Types
class Instance extends SubViewport:
	var id : int							= 0
	var npcs : Array[BaseAgent]				= []
	var mobs : Array[BaseAgent]				= []
	var players : Array[BaseAgent]			= []
	var map : Map							= null

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
		for i in Launcher.Conf.GetInt("Navigation", "navigationSpawnTry", Launcher.Conf.Type.NETWORK):
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

	inst.disable_3d = true
	inst.gui_disable_input = true
	inst.name = map.name
	inst.id = instanceID
	inst.map = map
	if inst.id > 0:
		inst.name += "_" + str(inst.id)
	map.instances.push_back(inst)

	for spawn in map.spawns:
		for i in spawn.count:
			var agent : BaseAgent = Launcher.DB.Instantiate.CreateAgent(spawn.type, spawn.name)

			Launcher.Util.Assert(agent != null, "Agent %s (type: %s) could not be created" % [spawn.name, spawn.type])
			if agent:
				var pos : Vector2 = Vector2.ZERO

				if spawn.is_global:
					pos = GetRandomPosition(map)
				else:
					pos = GetRandomPositionAABB(map, spawn.spawn_position, spawn.spawn_offset)
				Launcher.Util.Assert(pos != Vector2.ZERO, "Could not spawn the agent %s, no walkable position found" % spawn.name)
				if pos == Vector2.ZERO:
					agent.queue_free()
					continue

				agent.spawnInfo = spawn

				rids[agent.get_rid().get_id()] = agent
				Spawn(map, pos, agent, instanceID)

	Launcher.Root.call_deferred("add_child", inst)

# Agent Management
func CheckWarp(agent : BaseAgent):
	var prevMap : Object = Launcher.World.GetMapFromAgent(agent)
	if prevMap:
		for warp in prevMap.warps:
			if warp and Geometry2D.is_point_in_polygon(agent.get_position(), warp.polygon):
				var nextMap : Object = areas[warp.destinationMap]
				Warp(agent, nextMap, warp.destinationPos)
				return

func Warp(agent : BaseAgent, newMap : Map, newPos : Vector2i):
	Launcher.Util.Assert(newMap != null and agent != null, "Warp could not proceed, agent or current map missing")
	if agent and newMap:
		PopAgent(agent)
		Spawn(newMap, newPos, agent)

func Spawn(map : Map, pos : Vector2, agent : BaseAgent, instanceID : int = 0):
	Launcher.Util.Assert(map != null and instanceID < map.instances.size() and agent != null, "Spawn could not proceed, agent or map missing")
	if map and instanceID < map.instances.size() and agent:
		var inst : Instance = map.instances[instanceID]
		Launcher.Util.Assert(inst != null, "Spawn could not proceed, map instance missing")
		if inst:
			agent.set_position(pos)
			agent._velocity_computed(Vector2.ZERO)
			if agent.agent:
				agent.agent.set_navigation_map(map.mapRID)
			agent.ResetNav()

			PushAgent(agent, inst)
			if agent is PlayerAgent:
				var agentID = Launcher.Network.Server.GetRid(agent)
				Launcher.Util.OneShotCallback(agent.tree_entered, Launcher.Network.WarpPlayer, [map.name, agentID])

# Getters
func GetAgent(agentID : int) -> BaseAgent:
	var agent : BaseAgent = null
	if rids.has(agentID):
		agent = rids.get(agentID)
	Launcher.Util.Assert(agent != null, "Could not retrieve the world agent with the following ID %d" % [agentID])
	return agent

func GetInstanceFromAgent(agent : BaseAgent) -> SubViewport:
	var inst = agent.get_parent()
	Launcher.Util.Assert(inst != null && inst.is_class("SubViewport"), "Agent's base instance is incorrect, is type: " + inst.get_class() if inst else "null" )
	if inst && inst.is_class("SubViewport"):
		if not HasAgent(inst, agent):
			inst = null
	return inst

func GetMapFromAgent(agent : BaseAgent) -> Map:
	var map : Map = null
	var inst : Instance = GetInstanceFromAgent(agent)
	if inst:
		Launcher.Util.Assert(inst.map != null, "Agent's base map is incorrect, instance is not referenced inside a map")
		map = inst.map
	return map

func GetAgents(checkedAgent : BaseAgent) -> Array[Array]:
	var list : Array[Array] = []
	var instance : Instance = GetInstanceFromAgent(checkedAgent)
	if instance:
		list.append(instance.npcs)
		list.append(instance.mobs)
		list.append(instance.players)
	return list

func HasAgent(inst : Instance, agent : BaseAgent):
	var hasAgent : bool = false
	Launcher.Util.Assert(agent != null and inst != null, "Agent or instance are invalid, could not check if the agent is inside the instance")
	if agent and inst:
		if agent is PlayerAgent:
			hasAgent = inst.players.has(agent)
		elif agent is MonsterAgent:
			hasAgent = inst.mobs.has(agent)
		elif agent is NpcAgent:
			hasAgent = inst.npcs.has(agent)
	return hasAgent

func RemoveAgent(agent : BaseAgent):
	Launcher.Util.Assert(agent != null, "Agent is null, can't remove it")
	if agent:
		PopAgent(agent)
		rids.erase(agent)
		agent.queue_free()

func PopAgent(agent : BaseAgent):
	Launcher.Util.Assert(agent != null, "Agent is null, can't pop it")
	if agent:
		var inst : Instance = GetInstanceFromAgent(agent)
		Launcher.Network.Server.NotifyInstancePlayers(inst, agent, "RemoveEntity", [], false)
		if inst:
			if agent is PlayerAgent:
				inst.players.erase(agent)
			elif agent is MonsterAgent:
				inst.mobs.erase(agent)
			elif agent is NpcAgent:
				inst.npcs.erase(agent)
			inst.call_deferred("remove_child", agent)

func PushAgent(agent : BaseAgent, inst : Instance):
	Launcher.Util.Assert(agent != null, "Agent is null, can't push it")
	Launcher.Util.Assert(inst != null, "Instance is null, can't push the agent in it")		
	if agent and inst:
		if not HasAgent(inst, agent):
			if agent is PlayerAgent:
				inst.players.push_back(agent)
			elif agent is MonsterAgent:
				inst.mobs.push_back(agent)
			elif agent is NpcAgent:
				inst.npcs.push_back(agent)

			inst.call_deferred("add_child", agent)
			Launcher.Network.Server.NotifyInstancePlayers(inst, agent, "AddEntity", [agent.agentType, agent.agentID, agent.agentName, agent.position, agent.isSitting], false)
	else:
		RemoveAgent(agent)

# AI
func UpdateWalkPaths(agent : Node2D, map : Map):
	var randAABB : Vector2i = Vector2i(randi_range(30, 200), randi_range(30, 200))
	var newPos : Vector2i = GetRandomPositionAABB(map, agent.position, randAABB)
	agent.WalkToward(newPos)

func UpdateAI(agent : BaseAgent, map : Map):
	if not agent.hasCurrentGoal:
		if agent.aiTimer && agent.aiTimer.is_stopped():
			agent.aiTimer.StartTimer(randf_range(5, 15), UpdateWalkPaths.bind(agent, map))
	else:
		if agent.IsStuck():
			agent.ResetNav()
			agent.aiTimer.StartTimer(randf_range(2, 10), UpdateWalkPaths.bind(agent, map))

# Generic
func _post_launch():
	for mapName in Launcher.DB.MapsDB:
		var map : Map = Map.new()
		map.name = mapName
		LoadGenericData(map)
		LoadNavigationData(map)
		CreateInstance(map)
		areas[mapName] = map

func _physics_process(_dt : float):
	for map in areas.values():
		for instance in map.instances:
			if instance.players.size() > 0:
				for agent in instance.npcs:
					if agent:
						UpdateAI(agent, map)
						agent._internal_process()

				for agent in instance.mobs:
					if agent:
						UpdateAI(agent, map)
						agent._internal_process()

				for agent in instance.players:
					if agent:
						agent._internal_process()
