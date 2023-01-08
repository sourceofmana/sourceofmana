extends Node2D

# Types
class Instance:
	var id : int							= 0
	var npcs : Array						= []
	var mobs : Array						= []
	var players : Array						= []

class Map:
	var name : String						= ""
	var instances : Array					= []
	var navigation : Node2D					= null
	var triangulation : PackedInt32Array	= []
	var outlines : PackedVector2Array		= []

# Vars
var areas : Dictionary = {}

# Utils
func GenerateRandomPosition(map : Map) -> Vector2:
	Launcher.Util.Assert(map != null && map.triangulation.size() >= 3 && map.outlines.size() >= 3, "Map triangulation data is incomplete")
	if map && map.triangulation.size() >= 3 && map.outlines.size() >= 3:
		var randTriangleID : int = randi_range(0, map.triangulation.size() - 3)
		var a : Vector2 = map.outlines[map.triangulation[randTriangleID + 0]]
		var b : Vector2 = map.outlines[map.triangulation[randTriangleID + 1]]
		var c : Vector2 = map.outlines[map.triangulation[randTriangleID + 2]]
		return a + sqrt(randf()) * (-a + b + randf() * (c - b))

	return Vector2.ZERO

# Instance init
func ParseInformation(map : Map):
	var mapNode : Node2D = Launcher.Map.pool.LoadMap(map.name)
	if mapNode:
		if mapNode.has_node("Navigation"):
			map.navigation = mapNode.get_node("Navigation")

func GenerateTriangulation(map : Map):
	Launcher.Util.Assert(map != null && map.navigation != null, "Could not generate the triangulation as the map is lacking information")
	if map && map.navigation:
		if map.navigation && map.navigation.navpoly:
			for outline in map.navigation.navpoly.get_outline_count():
				var currentOutline : PackedVector2Array = map.navigation.navpoly.get_outline(outline)
				if map.outlines.size() < currentOutline.size():
					map.outlines = currentOutline
			map.triangulation = Geometry2D.triangulate_polygon(map.outlines)

func CreateInstance(map : Map, instanceID : int = 0):
	var inst : Instance = Instance.new()

	inst.id = instanceID
	inst.npcs.append(CreateEntity("Becees"))
	inst.mobs.append(CreateEntity("Phatyna"))
	inst.mobs.append(CreateEntity("Dorian"))
	inst.mobs.append(CreateEntity("Emil"))
	inst.mobs.append(CreateEntity("Gabriel"))
	inst.mobs.append(CreateEntity("Lilah"))
	inst.mobs.append(CreateEntity("Lulea"))
	inst.mobs.append(CreateEntity("Marvin"))

	map.instances.push_back(inst)

	for entity in inst.npcs + inst.players + inst.mobs:
		entity.position = GenerateRandomPosition(map)

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

# Entity Creation
func FindEntityReference(entityID : String) -> Object:
	var ref : Object = null
	for entityDB in Launcher.DB.EntitiesDB:
		if entityDB == entityID || Launcher.DB.EntitiesDB[entityDB]._name == entityID:
			ref = Launcher.DB.EntitiesDB[entityDB]
			break
	return ref

func CreateEntityInstance(entity : Object, isPlayable : bool) -> Node2D:
	var inst = null
	if entity:
		inst = Launcher.FileSystem.LoadScene("presets/Entity")
		inst.stat.moveSpeed = entity._walkSpeed

		if entity._ethnicity or entity._gender:
			inst.sprite = Launcher.FileSystem.LoadPreset("sprites/" + entity._ethnicity + entity._gender)
			if inst.sprite && entity._customTexture:
				inst.sprite.texture = Launcher.FileSystem.LoadGfx(entity._customTexture)
			inst.add_child(inst.sprite)
		if entity._animation:
			inst.animation = Launcher.FileSystem.LoadPreset("animations/" + entity._animation)
			var canFetchAnimTree = inst.animation != null && inst.animation.has_node("AnimationTree")
			Launcher.Util.Assert(canFetchAnimTree, "No AnimationTree found")
			if canFetchAnimTree:
				inst.animationTree = inst.animation.get_node("AnimationTree")
			inst.add_child(inst.animation)
		if entity._navigationAgent:
			inst.agent = Launcher.FileSystem.LoadPreset("navigations/" + entity._navigationAgent)
			inst.add_child(inst.agent)
		if entity._camera && isPlayable:
			inst.camera = Launcher.FileSystem.LoadPreset("cameras/" + entity._camera)
			inst.add_child(inst.camera)
		if entity._collision:
			inst.collision = Launcher.FileSystem.LoadPreset("collisions/" + entity._collision)
			inst.add_child(inst.collision)
		if entity._canWarp:
			inst.collision_layer |= 2
			inst.collision_mask |= 2

	return inst

func SetEntityName(inst : Object, entityID : String, entityName : String):
	if entityName.length() == 0:
		entityName = entityID
	inst.entityName = entityName
	inst.name = entityName

func CreateEntity(entityID : String, entityName : String = "", isPlayable : bool = false) -> Node2D:
	var inst : Object = null
	var ref : Object = FindEntityReference(entityID)
	if ref:
		inst = CreateEntityInstance(ref, isPlayable)
		SetEntityName(inst, entityID, entityName)

	Launcher.Util.Assert(inst != null, "Could not create the entity: " + entityID)
	return inst

# AI
func UpdateWalkPaths(entity : Node2D, map : Map):
	var newPos : Vector2 = GenerateRandomPosition(map)
	entity.WalkToward(newPos)

func UpdateAI(entity : Node2D, map : Map):
	if entity.isCapturingMouseInput == false && entity.AITimer && entity.AITimer.is_stopped():
		entity.AddAITimer(randi_range(5, 10), UpdateWalkPaths, map)
	elif entity.isCapturingMouseInput && entity.IsStuck():
		entity.ResetNav()
		entity.AddAITimer(randi_range(0, 3), UpdateWalkPaths, map)
	entity.UpdateInput()

# Generic
func _post_ready():
	for mapName in Launcher.DB.MapsDB:
		var map : Map = Map.new()
		map.name = mapName
		ParseInformation(map)
		GenerateTriangulation(map)
		CreateInstance(map)
		areas[mapName] = map

func _process(_dt : float):
	for map in areas.values():
		for instance in map.instances:
			if instance.players.size() > 0:
				for entity in instance.npcs + instance.mobs:
					UpdateAI(entity, map)
