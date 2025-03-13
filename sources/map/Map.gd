extends ServiceBase

#
signal MapUnloaded
signal MapLoaded
signal PlayerWarped

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

func GetMapBoundaries() -> Rect2:
	assert(currentMapNode != null, "Map node not found on the current scene")
	return currentMapNode.get_meta("MapBoundaries") if currentMapNode else Rect2()

#
func EmplaceMapNode(mapID : int):
	if currentMapID == mapID:
		return

	PhysicsServer2D.set_active(false)
	if currentMapNode:
		UnloadMapNode()
	LoadMapNode(mapID)
	PhysicsServer2D.set_active(true)

	if LauncherCommons.EnableMapPool:
		pool.RefreshPool(currentMapNode)

func UnloadMapNode():
	if currentMapNode:
		RemoveChildren()
		Launcher.remove_child(currentMapNode)
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
		if currentFringe:
			currentFringe.remove_child(child)
		if child != Launcher.Player:
			child.queue_free()

func AddChild(child : Node2D):
	assert(currentFringe != null, "Current fringe layer not found, could not add a new child")
	if currentFringe:
		currentFringe.add_child.call_deferred(child)

# Entities
func AddEntity(agentID : int, entityType : ActorCommons.Type, shape : int, spirit : int, currentShape : int, nick : String, entityVelocity : Vector2, entityPosition : Vector2i, entityOrientation : Vector2, state : ActorCommons.State, skillCastID : int):
	if not currentFringe:
		return

	var entityData : EntityData = DB.EntitiesDB.get(shape, null)
	if not entityData:
		return

	var entity : Entity = Entities.Get(agentID)
	var isLocalPlayer : bool = entityType == ActorCommons.Type.PLAYER and nick == Launcher.GUI.characterPanel.characterNameDisplay.get_text()
	var isAlreadySpawned : bool = entity != null and entity.get_parent() == currentFringe

	if not entity:
		if nick.is_empty():
			nick = entityData._name
		entity = Instantiate.CreateEntity(entityType, entityData, nick, isLocalPlayer)
		entity.agentID = agentID
		if isLocalPlayer:
			Launcher.Player = entity
			Launcher.Player.SetLocalPlayer()

	if entity:
		entity.stat.shape = shape
		entity.stat.spirit = spirit
		entity.stat.currentShape = currentShape

		if not isAlreadySpawned:
			Callback.OneShotCallback(entity.tree_entered, entity.Update, [entityVelocity, entityPosition, entityOrientation, state, skillCastID, isAlreadySpawned])
			AddChild(entity)
			Entities.Add(entity, agentID)
		else:
			entity.Update(entityVelocity, entityPosition, entityOrientation, state, skillCastID, isAlreadySpawned)

		if isLocalPlayer:
			PlayerWarped.emit()

func RemoveEntity(agentID : int):
	var entity : Entity = Entities.Get(agentID)
	if entity:
		if Launcher.Player.target == entity:
			Launcher.Player.target = null
		RemoveChild(entity)
		Entities.Erase(agentID)

func UpdateEntity(agentID : int, agentVelocity : Vector2, agentPosition : Vector2, agentOrientation : Vector2, agentState : ActorCommons.State, skillCastID : int):
	var entity : Entity = Entities.Get(agentID)
	if entity:
		entity.Update(agentVelocity, agentPosition, agentOrientation, agentState, skillCastID)

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

func Destroy():
	UnloadMapNode()
	Entities.Clear()
