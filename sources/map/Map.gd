extends Node2D

#
var Pool					= Launcher.FileSystem.LoadSource("map/MapPool.gd")
var activeMap : Node2D		= null

#
func RemoveMap(map : Node2D):
	if map:
		Launcher.call_deferred("remove_child", map)

func AddMap(map : Node2D):
	Launcher.call_deferred("add_child", map)

#
func RemoveEntityFromMap(entity : KinematicBody2D, map : Node2D):
	var fringeLayer : TileMap = map.get_node("Fringe")
	if fringeLayer:
		fringeLayer.call_deferred("remove_child", entity)

func AddEntityToMap(entity : KinematicBody2D, map : Node2D, newPos : Vector2):
		var fringeLayer : TileMap = map.get_node("Fringe")
		if fringeLayer:
			var entityPos : Vector2 = newPos * fringeLayer.cell_size + fringeLayer.cell_size / 2
			entity.set_position(entityPos)
			fringeLayer.call_deferred("add_child", entity)

#
func ApplyMapMetadata(map : Node2D):
	if map && map.has_meta("music"):
		Launcher.Audio.Load(map.get_meta("music") )

#
func Warp(_caller : Area2D, mapName : String, mapPos : Vector2, entity : Node2D = null):
	if entity == null:
		entity = Launcher.Entities.activePlayer

	if activeMap:
		if entity:
			RemoveEntityFromMap(entity, activeMap)
		RemoveMap(activeMap)

	activeMap = Pool.LoadMap(mapName)

	assert(activeMap, "Map instance could not be created")
	if activeMap:
		AddMap(activeMap)
		ApplyMapMetadata(activeMap)

		assert(entity, "Entity is not initialized, could not warp it to this map")
		if entity:
			AddEntityToMap(entity, activeMap, mapPos)
			if entity.get_node("PlayerCamera"):
				Launcher.Camera.SetBoundaries(entity)

		if Launcher.Conf.GetBool("MapPool", "enable", Launcher.Conf.Type.MAP):
			Pool.RefreshPool(activeMap)

#
func GetMapBoundaries(map : Node2D = null) -> Rect2:
	var boundaries : Rect2 = Rect2()

	if map == null:
		map = activeMap

	assert(map, "Map instance is not found, could not generate map boundaries")
	if map:
		var collisionLayer	= map.get_node("Collision")

		assert(collisionLayer, "Could not find a collision layer on map: " + map.get_name())
		if collisionLayer:
			var mapLimits			= collisionLayer.get_used_rect()
			var mapCellsize			= collisionLayer.cell_size

			boundaries.position.x	= mapCellsize.x * mapLimits.position.x
			boundaries.end.x		= mapCellsize.x * mapLimits.end.x
			boundaries.position.y	= mapCellsize.y * mapLimits.position.y
			boundaries.end.y		= mapCellsize.y * mapLimits.end.y

	return boundaries
