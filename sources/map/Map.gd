extends Node2D

#
signal PlayerWarped

#
var pool					= Launcher.FileSystem.LoadSource("map/MapPool.gd")
var mapNode : Node2D		= null

#
func GetTileMap() -> TileMap:
	var tilemap : TileMap = null
	if mapNode:
		for child in mapNode.get_children():
			if child is TileMap:
				tilemap = child
				break
	return tilemap

func GetMapBoundaries() -> Rect2:
	var boundaries : Rect2 = Rect2()
	var tilemap : TileMap = GetTileMap()
	Launcher.Util.Assert(tilemap != null, "Could not find a tilemap on the current scene")
	if tilemap:
		var mapLimits			= tilemap.get_used_rect()
		var mapCellsize			= tilemap.get_tileset().get_tile_size() if tilemap.get_tileset() else Vector2i(32, 32)

		boundaries.position.x	= mapCellsize.x * mapLimits.position.x
		boundaries.end.x		= mapCellsize.x * mapLimits.end.x
		boundaries.position.y	= mapCellsize.y * mapLimits.position.y
		boundaries.end.y		= mapCellsize.y * mapLimits.end.y

	return boundaries

#
func UnloadMapNode():
	if mapNode:
		RemoveChilds()
		Launcher.call_deferred("remove_child", mapNode)
		mapNode = null

func LoadMapNode(mapName : String):
	mapNode = pool.LoadMap(mapName)
	Launcher.Util.Assert(mapNode != null, "Map instance could not be created")
	if mapNode:
		Launcher.call_deferred("add_child", mapNode)

#
func RemoveChilds():
	var tileMap : TileMap = GetTileMap()
	if tileMap:
		for entity in tileMap.get_children():
			entity.set_physics_process(false)
			tileMap.call_deferred("remove_child", entity)

func AddChild(entity : CharacterBody2D):
	var tilemap : TileMap = GetTileMap()
	tilemap.call_deferred("add_child", entity)
	entity.set_physics_process(true)

#
func WarpEntity(mapName : String, mapPos : Vector2, pc : CharacterBody2D):
	assert(pc, "Entity is not initialized, could not warp it to this map")

	if mapNode && mapNode.get_name() != mapName:
		Launcher.World.Warp(mapNode.get_name(), mapName, pc)
		UnloadMapNode()
	LoadMapNode(mapName)
	Launcher.Camera.SetBoundaries(pc)

	if mapNode:
		if pc:
			for entity in Launcher.World.GetEntities(mapName, pc.entityName):
				AddChild(entity)
			pc.set_position(mapPos)
			pc.ResetNav()
				
		if Launcher.Conf.GetBool("MapPool", "enable", Launcher.Conf.Type.MAP):
			pool.RefreshPool(mapNode)
		emit_signal('PlayerWarped')
