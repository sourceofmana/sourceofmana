extends ServiceBase

#
signal PlayerWarped

#
var pool								= FileSystem.LoadSource("map/MapPool.gd")
var mapNode : Node2D					= null
var fringeLayer : TileMapLayer			= null

#
func RefreshTileMap():
	for child in mapNode.get_children():
		if child is TileMapLayer and child.name == "Fringe":
			fringeLayer = child
			break

func GetMapBoundaries() -> Rect2:
	Util.Assert(mapNode != null, "Map node not found on the current scene")
	return mapNode.get_meta("MapBoundaries") if mapNode else Rect2()

#
func EmplaceMapNode(mapName : String):
	if mapNode && mapNode.get_name() == mapName:
		return

	PhysicsServer2D.set_active(false)

	if mapNode:
		UnloadMapNode()
	LoadMapNode(mapName)

	PhysicsServer2D.set_active(true)

	if LauncherCommons.EnableMapPool:
		pool.RefreshPool(mapNode)

func UnloadMapNode():
	if mapNode:
		RemoveChildren()
		Launcher.remove_child(mapNode)
		mapNode = null
		fringeLayer = null
		Entities.Clear()

func LoadMapNode(mapName : String):
	mapNode = pool.LoadMapClientData(mapName)
	Util.Assert(mapNode != null, "Map instance could not be created")
	if mapNode:
		RefreshTileMap()
		Launcher.add_child(mapNode)

#
func RemoveChildren():
	Util.Assert(fringeLayer != null, "Current fringe layer not found, could not remove children")
	for entity in fringeLayer.get_children():
		RemoveChild(entity as Entity)

func RemoveChild(entity : Entity):
	if entity:
		if fringeLayer:
			fringeLayer.remove_child(entity)
		if entity != Launcher.Player:
			entity.queue_free()

func AddChild(entity : Entity):
	Util.Assert(fringeLayer != null, "Current fringe layer not found, could not add a new child entity")
	if fringeLayer:
		fringeLayer.add_child(entity)

#
func AddEntity(agentID : int, entityType : ActorCommons.Type, entityID : String, nick : String, entityVelocity : Vector2, entityPosition : Vector2i, entityOrientation : Vector2, state : ActorCommons.State, skillCastID : int):
	if not fringeLayer:
		return

	var entity : Entity = Entities.Get(agentID)
	var isLocalPlayer : bool = entityType == ActorCommons.Type.PLAYER and nick == Launcher.FSM.playerName
	var isAlreadySpawned : bool = entity != null and entity.get_parent() == fringeLayer

	if isLocalPlayer and Launcher.Player:
		entity = Launcher.Player
	if not entity:
		entity = Instantiate.CreateEntity(entityType, entityID, nick)
		entity.agentID = agentID
		if isLocalPlayer:
			Launcher.Player = entity
			Launcher.Player.SetLocalPlayer()

	if entity:
		if not isAlreadySpawned:
			Callback.OneShotCallback(entity.tree_entered, entity.Update, [entityVelocity, entityPosition, entityOrientation, state, skillCastID, isAlreadySpawned])
			AddChild(entity)
			Entities.Add(entity, agentID)
		else:
			entity.Update(entityVelocity, entityPosition, entityOrientation, state, skillCastID, isAlreadySpawned)

		if isLocalPlayer:
			emit_signal('PlayerWarped')

func RemoveEntity(agentID : int):
	var entity : Entity = Entities.Get(agentID)
	if entity:
		RemoveChild(entity)
		Entities.Erase(agentID)

func UpdateEntity(agentID : int, agentVelocity : Vector2, agentPosition : Vector2, agentOrientation : Vector2, agentState : ActorCommons.State, skillCastID : int):
	var entity : Entity = Entities.Get(agentID)
	if entity:
		entity.Update(agentVelocity, agentPosition, agentOrientation, agentState, skillCastID)
