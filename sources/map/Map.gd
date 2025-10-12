extends ServiceBase

#
signal MapUnloaded
signal MapLoaded
signal PlayerWarped
signal PlayerMoved

#
var pool								= FileSystem.LoadSource("map/MapPool.gd")
var currentMapID : int					= DB.UnknownHash
var currentMapNode : Node2D				= null
var currentFringe : TileMapLayer		= null
var drops : Dictionary[int, Sprite2D]	= {}

#
func RefreshTileMap():
	for child in currentMapNode.get_children():
		if child is TileMapLayer and child.name == "Fringe":
			currentFringe = child
			break

func GetMapBoundaries() -> Vector2:
	assert(currentMapNode != null, "Map node not found on the current scene")
	return currentMapNode.get_meta("MapBoundaries", Vector2.ZERO) if currentMapNode else Vector2.ZERO

#
func EmplaceMapNode(mapID : int, force : bool = false):
	if not force and currentMapID == mapID:
		return

	if currentMapNode:
		UnloadMapNode()
	LoadMapNode(mapID)

	if LauncherCommons.EnableMapPool:
		pool.RefreshPool()

func UnloadMapNode():
	if currentMapNode:
		RemoveChildren()
		Launcher.remove_child.call_deferred(currentMapNode)
		currentMapID = DB.UnknownHash
		currentMapNode = null
		currentFringe = null
		drops.clear()
		Entities.Clear()
		MapUnloaded.emit()

func LoadMapNode(mapID : int):
	currentMapNode = pool.LoadMapClientData(mapID)
	currentMapID = mapID
	assert(currentMapNode != null, "Map instance could not be created")
	if currentMapNode:
		RefreshTileMap()
		Launcher.add_child.call_deferred(currentMapNode)
		MapLoaded.emit()

# Generic fringe Node2D
func RemoveChildren():
	assert(currentFringe != null, "Current fringe layer not found, could not remove children")
	for child in currentFringe.get_children():
		if child is Node2D:
			RemoveChild(child)

func RemoveChild(child : Node2D):
	if child:
		if currentFringe and child.get_parent() == currentFringe:
			currentFringe.remove_child.call_deferred(child)
		if child != Launcher.Player:
			child.queue_free()

func AddChild(child : Node2D):
	assert(currentFringe != null, "Current fringe layer not found, could not add a new child")
	if currentFringe:
		currentFringe.add_child.call_deferred(child)

# Entities
func AddPlayer(agentRID : int, actorType : ActorCommons.Type, shape : int, spirit : int, currentShape : int, nick : String, entityVelocity : Vector2, entityPosition : Vector2i, entityOrientation : Vector2, state : ActorCommons.State, skillCastID : int) -> Entity:
	var entity : Entity = AddEntity(agentRID, actorType, shape, spirit, currentShape, nick, entityVelocity, entityPosition, entityOrientation, state, skillCastID)
	if entity and entity == Launcher.Player:
		PlayerWarped.emit()
	return entity

func AddEntity(agentRID : int, actorType : ActorCommons.Type, shape : int, spirit : int, currentShape : int, nick : String, entityVelocity : Vector2, entityPosition : Vector2i, entityOrientation : Vector2, state : ActorCommons.State, skillCastID : int) -> Entity:
	if not currentFringe:
		return null

	var entityData : EntityData = DB.EntitiesDB.get(shape, null)
	if not entityData:
		return null

	var entity : Entity = Entities.Get(agentRID)
	var isAlreadySpawned : bool = entity != null and entity.get_parent() == currentFringe
	var isPlayerType : bool = actorType == ActorCommons.Type.PLAYER

	if not entity:
		var isLocalPlayer : bool = isPlayerType and nick == Launcher.GUI.characterPanel.characterNameDisplay.get_text()
		entity = Instantiate.CreateEntity(actorType, entityData, entityData._name if nick.is_empty() else nick, isLocalPlayer)
		if not entity:
			return

		entity.agentRID = agentRID
		if isLocalPlayer:
			Launcher.Player = entity
			Launcher.Player.SetLocalPlayer()

	entity.stat.shape = shape
	entity.stat.spirit = spirit
	entity.stat.currentShape = currentShape

	if not isAlreadySpawned:
		AddChild(entity)
		Entities.Add(entity, agentRID)
	entity.Update(entityVelocity, entityPosition, entityOrientation, state, skillCastID, isAlreadySpawned or isPlayerType)

	return entity

func RemoveEntity(agentRID : int):
	var entity : Entity = Entities.Get(agentRID)
	if entity:
		if Launcher.Player.target == entity:
			Launcher.Player.target = null
		RemoveChild(entity)
		Entities.Erase(agentRID)

func FullUpdateEntity(agentRID : int, agentVelocity : Vector2, agentPosition : Vector2, agentOrientation : Vector2, agentState : ActorCommons.State, skillCastID : int):
	var entity : Entity = Entities.Get(agentRID)
	if entity:
		entity.Update(agentVelocity, agentPosition, agentOrientation, agentState, skillCastID)

func UpdateEntity(agentRID : int, agentVelocity : Vector2, agentPosition : Vector2):
	var entity : Entity = Entities.Get(agentRID)
	if entity and entity.visual:
		var agentOrientation : Vector2 = entity.entityOrientation if agentVelocity.is_zero_approx() else agentVelocity.normalized()
		entity.Update(agentVelocity, agentPosition, agentOrientation, entity.state, entity.visual.skillCastID)

func LeaveGame():
	UnloadMapNode()
	Launcher.Player = null
	Entities.Clear()

# Drops
func AddDrop(dropID : int, cell : BaseCell, pos : Vector2):
	if not cell or not currentFringe:
		return

	if dropID not in drops:
		var dropNode : Sprite2D = Instantiate.CreateDrop(cell, pos)
		if dropNode:
			AddChild(dropNode)
			drops[dropID] = dropNode

func RemoveDrop(dropID : int):
	var drop : Sprite2D = drops.get(dropID)
	if drop:
		RemoveChild(drop)
		drops.erase(dropID)

func PickupNearestDrop():
	var nearestID : int = -1
	var nearestLengthSquared : float = ActorCommons.PickupSquaredDistance
	for dropID in drops:
		var drop : Node2D = drops.get(dropID)
		if drop != null:
			var lengthSquared : float = Launcher.Player.position.distance_squared_to(drop.position)
			if lengthSquared < nearestLengthSquared:
				nearestLengthSquared = lengthSquared
				nearestID = dropID
	if nearestID > 0:
		Network.PickupDrop(nearestID)

#
func _post_launch():
	isInitialized = true
	FSM.exit_game.connect(LeaveGame)

func Destroy():
	LeaveGame()
