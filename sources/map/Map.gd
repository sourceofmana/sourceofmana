extends Node2D

#
signal PlayerWarped

#
var pool								= Launcher.FileSystem.LoadSource("map/MapPool.gd")
var mapNode : Node2D					= null
var entities : Dictionary				= {}

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
	mapNode = pool.LoadMapClientData(mapName)
	Launcher.Util.Assert(mapNode != null, "Map instance could not be created")
	if mapNode:
		Launcher.call_deferred("add_child", mapNode)

#
func RemoveChilds():
	var tileMap : TileMap = GetTileMap()
	if tileMap:
		for entity in tileMap.get_children():
			tileMap.call_deferred("remove_child", entity)

func AddChild(entity : CharacterBody2D):
	var tilemap : TileMap = GetTileMap()
	tilemap.call_deferred("add_child", entity)

#
func ReplaceMapNode(mapName : String):
	if mapNode && mapNode.get_name() != mapName:
		UnloadMapNode()
	LoadMapNode(mapName)
	Launcher.Network.GetAgents()

	if mapNode:
		if Launcher.Conf.GetBool("MapPool", "enable", Launcher.Conf.Type.MAP):
			pool.RefreshPool(mapNode)

#
func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityPos : Vector2i):
	var isLocalPlayer : bool = entityName == Launcher.FSM.playerName
	var entity : BaseEntity = null
	if isLocalPlayer and Launcher.Player:
		entity = Launcher.Player
	else:
		entity = Launcher.DB.Instantiate.CreateEntity(entityType, entityID, entityName)
		if entity && isLocalPlayer:
			Launcher.Player = entity
			Launcher.Player.SetLocalPlayer()
			if Launcher.Debug:
				Launcher.Debug.SetPlayerInventory()
			if Launcher.FSM:
				Launcher.FSM.emit_signal("enter_game")

	if entity:
		entity.set_position(entityPos)
		AddChild(entity)
		entities[agentID] = entity

		if isLocalPlayer:
			if Launcher.Camera:
				Launcher.Camera.SetBoundaries()
			emit_signal('PlayerWarped')

func UpdateEntity(agentID : int, agentVelocity : Vector2, agentPosition : Vector2, isSitting : bool):
	var entity : BaseEntity = entities.get(agentID)
	if entity && entity.get_parent():
		entity.Update(agentVelocity, agentPosition, isSitting)
