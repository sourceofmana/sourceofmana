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
	Util.Assert(tilemap != null, "Could not find a tilemap on the current scene")
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
	Util.Assert(mapNode != null, "Map instance could not be created")
	if mapNode:
		Launcher.call_deferred("add_child", mapNode)

#
func RemoveChilds():
	var tilemap : TileMap = GetTileMap()
	Util.Assert(tilemap != null, "Current tilemap not found, could not remove children")
	if tilemap:
		for entity in tilemap.get_children():
			tilemap.call_deferred("remove_child", entity)

func RemoveChild(entity : BaseEntity):
	var tilemap : TileMap = GetTileMap()
	Util.Assert(tilemap != null, "Current tilemap not found, could not remove a child entity")
	if tilemap:
		tilemap.call_deferred("remove_child", entity)

func AddChild(entity : BaseEntity):
	var tilemap : TileMap = GetTileMap()
	Util.Assert(tilemap != null, "Current tilemap not found, could not add a new child entity")
	if tilemap:
		tilemap.call_deferred("add_child", entity)

#
func ReplaceMapNode(mapName : String):
	if mapNode && mapNode.get_name() != mapName:
		UnloadMapNode()
	LoadMapNode(mapName)
	Launcher.Network.GetEntities()

	if mapNode:
		if Launcher.Conf.GetBool("MapPool", "enable", Launcher.Conf.Type.MAP):
			pool.RefreshPool(mapNode)

#
func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityPos : Vector2i, entityState : EntityCommons.State):
	var isLocalPlayer : bool = entityName == Launcher.FSM.playerName
	var entity : BaseEntity = null
	if GetTileMap():
		if isLocalPlayer and Launcher.Player:
			entity = Launcher.Player
		else:
			entity = Instantiate.CreateEntity(entityType, entityID, entityName)
			if entity && isLocalPlayer:
				Launcher.Player = entity
				Launcher.Player.SetLocalPlayer()
				if Launcher.FSM:
					Launcher.FSM.emit_signal("enter_game")

	if entity:
		entity.set_position(entityPos)
		entity.Update(Vector2.ZERO, entityPos, entityState)

		AddChild(entity)
		entities[agentID] = entity

		if isLocalPlayer:
			emit_signal('PlayerWarped')

func RemoveEntity(agentID : int):
	var entity : BaseEntity = entities.get(agentID)
	if entity:
		RemoveChild(entity)

func UpdateEntity(agentID : int, agentVelocity : Vector2, agentPosition : Vector2, agentState : EntityCommons.State):
	var entity : BaseEntity = entities.get(agentID)
	if entity:
		if entity == Launcher.Player:
			print("Client received -> " + str(agentVelocity))
		entity.Update(agentVelocity, agentPosition, agentState)

func EmotePlayer(agentID : int, emoteID : int):
	var entity : BaseEntity = entities.get(agentID)
	if entity && entity.get_parent() && entity.interactive:
		entity.interactive.DisplayEmote(emoteID)
