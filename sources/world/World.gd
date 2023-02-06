extends Node2D

# Types
class Instance:
	var id : int							= 0
	var npcs : Array[NpcEntity]				= []
	var mobs : Array[MonsterEntity]			= []
	var players : Array[PlayerEntity]		= []

class Map:
	var name : String						= ""
	var instances : Array					= []
	var spawns : Array						= []
	var warps : Array						= []
	var nav_poly : NavigationPolygon		= null
	var mapRID : RID						= RID()
	var regionRID : RID						= RID()

# Vars
var areas : Dictionary = {}

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

		if map.nav_poly:
			map.mapRID = NavigationServer2D.map_create()
			NavigationServer2D.map_set_active(map.mapRID, true)

			map.regionRID = NavigationServer2D.region_create()
			NavigationServer2D.region_set_map(map.regionRID, map.mapRID)
			NavigationServer2D.region_set_navigation_polygon(map.regionRID, map.nav_poly)

			NavigationServer2D.map_force_update(map.mapRID)

func CreateInstance(map : Map, instanceID : int = 0):
	var inst : Instance = Instance.new()

	inst.id = instanceID
	for spawn in map.spawns:
		for i in spawn.count:
#			Add check to spawn something else than mobs
			var entity : BaseEntity = null
			match spawn.type:
				"Player":	entity = CreateEntity(spawn.type, spawn.name)
				"Npc":		entity = CreateEntity(spawn.type, spawn.name)
				"Monster":	entity = CreateEntity(spawn.type, spawn.name)
				"Trigger":	entity = CreateEntity(spawn.type, spawn.name)
				_: Launcher.Util.Assert(false, "Entity type is not valid")

			if spawn.is_global:
				entity.position = GetRandomPosition(map)
			else:
				entity.position = GetRandomPositionAABB(map, spawn.spawn_position, spawn.spawn_offset)

			# TODO: use internal Spawn function
			Launcher.Util.Assert(entity.position != Vector2.ZERO, "Could not spawn the entity %s, no walkable position found" % spawn.name)
			if entity.position != Vector2.ZERO:
				match spawn.type:
					"Player":	inst.players.append(entity)
					"Npc":		inst.npcs.append(entity)
					"Monster":	inst.mobs.append(entity)
					"Trigger":	inst.npcs.append(entity)
					_: Launcher.Util.Assert(false, "Entity type is not valid")

	map.instances.push_back(inst)

	for entity in inst.npcs + inst.players + inst.mobs:
		if entity.agent:
			entity.agent.set_navigation_map(map.mapRID)

# Entities Management
func Warp(oldMap : String, newMap : String, entity : Node2D):
	var err : bool = false
	err = err || not areas.has(oldMap)
	err = err || entity == null
	Launcher.Util.Assert(not err, "WarpEntity could not proceed, one or multiple parameters are invalid")

	if not err:
		err = true
		for instance in areas[oldMap].instances:
			var arrayIdx : int = instance.players.find(entity)
			if arrayIdx >= 0:
				instance.players.remove_at(arrayIdx)
				err = false
	Launcher.Util.Assert(not err, "WarpEntity could not proceed, the entity is not found on old map's instances")
	
	Spawn(newMap, entity)

func Spawn(newMap : String, entity : Node2D, instID : int = 0):
	var err : bool = false
	err = err || not areas.has(newMap)
	err = err || entity == null
	Launcher.Util.Assert(not err, "WarpEntity could not proceed, one or multiple parameters are invalid")

	if not err:
		if entity.agent:
			entity.agent.set_navigation_map(areas[newMap].mapRID)

		var inst : Instance = areas[newMap].instances[instID]
		var arrayIdx : int = inst.players.find(entity)
		if arrayIdx < 0:
			inst.players.push_back(entity)
		else:
			err = true
	Launcher.Util.Assert(not err, "WarpEntity could not proceed, the entity is not found on new map's instances")

func GetEntities(mapName : String, playerName : String):
	var list : Array = []
	var area : Map = areas[mapName] if areas.has(mapName) else null
	Launcher.Util.Assert(area != null, "World can't find the map name " + mapName)
	if area:
		for instance in area.instances:
			for entity in instance.players:
				if entity.entityName == playerName:
					list = instance.npcs + instance.mobs + instance.players
					break
	return list

func HasEntity(entityName : String, checkPlayers = true, checkNpcs = true, checkMonsters = true):
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for entity in \
				instance.players if checkPlayers else [] + \
				instance.npcs if checkNpcs else [] + \
				instance.mobs if checkMonsters else []:
					if entity.entityName == entityName:
						return true
	return false

func RemoveEntity(entityName : String, checkPlayers = true, checkNpcs = true, checkMonsters = true):
	for map in areas.values():
		for instance in map.instances:
			if checkPlayers:
				for entity in instance.players:
					if entity.entityName == entityName:
						instance.players.erase(entity)
			if checkNpcs:
				for entity in instance.npcs:
					if entity.entityName == entityName:
						instance.npcs.erase(entity)
			if checkMonsters:
				for entity in instance.mobs:
					if entity.entityName == entityName:
						instance.mobs.erase(entity)

# Entity Creation
func FindEntityReference(entityID : String) -> Object:
	var ref : Object = null
	for entityDB in Launcher.DB.EntitiesDB:
		if entityDB == entityID || Launcher.DB.EntitiesDB[entityDB]._name == entityID:
			ref = Launcher.DB.EntitiesDB[entityDB]
			break
	return ref

func CreateEntity(entityType : String, entityID : String, entityName : String = "", isLocalPlayer : bool = false) -> BaseEntity:
	var inst : BaseEntity = null
	var template = FindEntityReference(entityID)
	if template:
		inst = Launcher.FileSystem.LoadEntity(entityType)
		if inst:
			if isLocalPlayer:
				inst.SetLocalPlayer()
			inst.applyEntityData(template)
			inst.SetName(entityID, entityName)
	Launcher.Util.Assert(inst != null, "Could not create the entity: " + entityID)
	return inst

# AI
func UpdateWalkPaths(entity : Node2D, map : Map):
	var randAABB : Vector2i = Vector2i(randi_range(30, 200), randi_range(30, 200))
	var newPos : Vector2i = GetRandomPositionAABB(map, entity.position, randAABB)
	entity.WalkToward(newPos)

func UpdateAI(entity : BaseEntity, map : Map):
#	if entity is PlayerEntity:
#	if entity is NpcEntity:
#	if entity is MonsterEntity:

	if entity.hasGoal == false && entity.AITimer && entity.AITimer.is_stopped():
		entity.StartAITimer(randf_range(5, 15), UpdateWalkPaths, map)
	elif entity.hasGoal && entity.IsStuck():
		entity.ResetNav()
		entity.StartAITimer(randf_range(2, 10), UpdateWalkPaths, map)
	entity.UpdateInput()

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
			if instance.players.size() > 0:
				for entity in instance.npcs + instance.mobs:
					UpdateAI(entity, map)
