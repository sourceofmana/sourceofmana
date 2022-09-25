extends Node2D

#
signal PlayerWarped

#
var Pool					= Launcher.FileSystem.LoadSource("map/MapPool.gd")
var activeMap : Node2D		= null

#
func RemoveMap(map : Node2D):
	if map:
		Launcher.call_deferred("remove_child", map)

func AddMap(map : Node2D):
	if map:
		Launcher.call_deferred("add_child", map)

func GetTileMap(map : Node2D) -> TileMap:
	var tilemap : TileMap = null
	if map:
		for child in map.get_children():
			if child is TileMap:
				tilemap = child
				break
	return tilemap

#
func RemoveEntityFromMap(entity : CharacterBody2D, map : Node2D):
	var tilemap : TileMap = GetTileMap(map)
	if tilemap:
		entity.set_physics_process(false)
		tilemap.call_deferred("remove_child", entity)

func AddEntityToMap(entity : CharacterBody2D, map : Node2D, newPos : Vector2):
	var tilemap : TileMap = GetTileMap(map)
	if tilemap && tilemap.get_tileset():
		var cellSize : Vector2 = tilemap.get_tileset().get_tile_size()
		var entityPos : Vector2 = newPos * cellSize + cellSize / 2
		entity.set_position(entityPos)
		tilemap.call_deferred("add_child", entity)
	entity.Warped(map)
	entity.set_physics_process(true)

#
func Warp(_caller : Area2D, mapName : String, mapPos : Vector2, entity : CharacterBody2D):
	assert(entity, "Entity is not initialized, could not warp it to this map")

	if activeMap && activeMap.get_name() != mapName:
		if entity:
			RemoveEntityFromMap(entity, activeMap)
		RemoveMap(activeMap)
		activeMap = null

	if not activeMap:
		activeMap = Pool.LoadMap(mapName)
		Launcher.Util.Assert(activeMap != null, "Map instance could not be created")
		if activeMap:
			AddMap(activeMap)
			if entity:
				Launcher.Camera.SetBoundaries(entity)

	if activeMap:
		if entity:
			AddEntityToMap(entity, activeMap, mapPos)

		if Launcher.Conf.GetBool("MapPool", "enable", Launcher.Conf.Type.MAP):
			Pool.RefreshPool(activeMap)

		emit_signal('PlayerWarped')

#
func GetMapBoundaries(map : Node2D = null) -> Rect2:
	var boundaries : Rect2 = Rect2()

	if map == null:
		map = activeMap

	Launcher.Util.Assert(map != null, "Map instance is not found, could not generate map boundaries")

	var tilemap : TileMap = GetTileMap(map)
	Launcher.Util.Assert(tilemap != null, "Could not find a tilemap on this map scene: " + str(map.get_name()))
	if tilemap:
		var mapLimits			= tilemap.get_used_rect()
		var mapCellsize			= tilemap.get_tileset().get_tile_size() if tilemap.get_tileset() else Vector2i(32, 32)

		boundaries.position.x	= mapCellsize.x * mapLimits.position.x
		boundaries.end.x		= mapCellsize.x * mapLimits.end.x
		boundaries.position.y	= mapCellsize.y * mapLimits.position.y
		boundaries.end.y		= mapCellsize.y * mapLimits.end.y

	return boundaries
