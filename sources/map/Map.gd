extends ServiceBase

#
signal PlayerWarped

#
var pool								= FileSystem.LoadSource("map/MapPool.gd")
var mapNode : Node2D					= null
var tilemapNode : TileMap				= null
var entities : Dictionary				= {}

#
func RefreshTileMap():
	for child in mapNode.get_children():
		if child is TileMap:
			tilemapNode = child
			break

func GetMapBoundaries() -> Rect2:
	var boundaries : Rect2 = Rect2()
	Util.Assert(tilemapNode != null, "Could not find a tilemap on the current scene")
	if tilemapNode:
		var mapLimits			= tilemapNode.get_used_rect()
		var mapCellsize			= tilemapNode.get_tileset().get_tile_size() if tilemapNode.get_tileset() else Vector2i(32, 32)

		boundaries.position.x	= mapCellsize.x * mapLimits.position.x
		boundaries.end.x		= mapCellsize.x * mapLimits.end.x
		boundaries.position.y	= mapCellsize.y * mapLimits.position.y
		boundaries.end.y		= mapCellsize.y * mapLimits.end.y

	return boundaries

#
func EmplaceMapNode(mapName : String):
	PhysicsServer2D.set_active(false)

	if mapNode && mapNode.get_name() != mapName:
		UnloadMapNode()
	LoadMapNode(mapName)

	PhysicsServer2D.set_active(true)

	if Launcher.Conf.GetBool("MapPool", "enable", Launcher.Conf.Type.MAP):
		pool.RefreshPool(mapNode)

func UnloadMapNode():
	if mapNode:
		RemoveChildren()
		Launcher.remove_child(mapNode)
		mapNode = null
		tilemapNode = null
		entities.clear()

func LoadMapNode(mapName : String):
	mapNode = pool.LoadMapClientData(mapName)
	Util.Assert(mapNode != null, "Map instance could not be created")
	if mapNode:
		RefreshTileMap()
		Launcher.add_child(mapNode)

#
func RemoveChildren():
	Util.Assert(tilemapNode != null, "Current tilemap not found, could not remove children")
	for entity in tilemapNode.get_children():
		RemoveChild(entity)


func RemoveChild(entity : BaseEntity):
	if tilemapNode:
		tilemapNode.remove_child(entity)
	if not entity is PlayerEntity:
		entity.queue_free()

func AddChild(entity : BaseEntity):
	Util.Assert(tilemapNode != null, "Current tilemap not found, could not add a new child entity")
	if tilemapNode:
		tilemapNode.add_child(entity)

#
func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityVelocity : Vector2, entityPosition : Vector2i, entityOrientation : Vector2, entityState : EntityCommons.State):
	var isLocalPlayer : bool = entityName == Launcher.FSM.playerName and entityType == "Player"
	var entity : BaseEntity = null
	if tilemapNode:
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
		entity.Update(entityVelocity, entityPosition, entityOrientation, entityState)

		AddChild(entity)
		entities[agentID] = entity

		if isLocalPlayer:
			emit_signal('PlayerWarped')

func RemoveEntity(agentID : int):
	var entity : BaseEntity = entities.get(agentID)
	if entity:
		RemoveChild(entity)
		entities.erase(agentID)

func UpdateEntity(agentID : int, agentVelocity : Vector2, agentPosition : Vector2, agentOrientation : Vector2, agentState : EntityCommons.State):
	var entity : BaseEntity = entities.get(agentID)
	if entity:
		entity.Update(agentVelocity, agentPosition, agentOrientation, agentState)

func EmotePlayer(agentID : int, emoteID : int):
	var entity : BaseEntity = entities.get(agentID)
	if entity && entity.get_parent() && entity.interactive:
		entity.interactive.DisplayEmote(emoteID)
