extends ServiceBase

#
signal MapUnloaded
signal MapLoaded
signal PlayerWarped

#
var pool								= FileSystem.LoadSource("map/MapPool.gd")
var mapNode : Node2D					= null
var fringeLayer : TileMapLayer			= null
var drops : Dictionary					= {}

#
func RefreshTileMap():
	for child in mapNode.get_children():
		if child is TileMapLayer and child.name == "Fringe":
			fringeLayer = child
			break

func GetMapBoundaries() -> Rect2:
	assert(mapNode != null, "Map node not found on the current scene")
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
		drops.clear()
		Entities.Clear()
		MapUnloaded.emit()

func LoadMapNode(mapName : String):
	mapNode = pool.LoadMapClientData(mapName)
	assert(mapNode != null, "Map instance could not be created")
	if mapNode:
		RefreshTileMap()
		Launcher.add_child(mapNode)
		MapLoaded.emit()

# Generic fringe Node2D
func RemoveChildren():
	assert(fringeLayer != null, "Current fringe layer not found, could not remove children")
	for child in fringeLayer.get_children():
		if child is Node2D:
			RemoveChild(child)

func RemoveChild(child : Node2D):
	if child:
		if fringeLayer:
			fringeLayer.remove_child(child)
		if child != Launcher.Player:
			child.queue_free()

func AddChild(child : Node2D):
	assert(fringeLayer != null, "Current fringe layer not found, could not add a new child")
	if fringeLayer:
		fringeLayer.add_child(child)

# Entities
func AddEntity(agentID : int, entityType : ActorCommons.Type, entityID : String, nick : String, entityVelocity : Vector2, entityPosition : Vector2i, entityOrientation : Vector2, state : ActorCommons.State, skillCastID : int):
	if not fringeLayer:
		return

	var entity : Entity = Entities.Get(agentID)
	var isLocalPlayer : bool = entityType == ActorCommons.Type.PLAYER and nick == Launcher.FSM.playerName
	var isAlreadySpawned : bool = entity != null and entity.get_parent() == fringeLayer

	if isLocalPlayer and Launcher.Player:
		entity = Launcher.Player
	if not entity:
		entity = Instantiate.CreateEntity(entityType, entityID, nick, isLocalPlayer)
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
	if not fringeLayer:
		return

	if dropID not in drops:
		var dropNode : Sprite2D = Instantiate.CreateDrop(cell, pos)
		if dropNode:
			AddChild(dropNode)
			drops[dropID] = dropNode

func RemoveDrop(dropID : int):
	if dropID in drops:
		RemoveChild(drops[dropID])
		drops.erase(dropID)

func PickupNearestDrop():
	var nearestID : int = -1
	var nearestLengthSquared : float = ActorCommons.PickupSquaredDistance
	for dropID in drops:
		var drop : Node2D = drops[dropID]
		if drop != null:
			var lengthSquared : float = Launcher.Player.position.distance_squared_to(drop.position)
			if lengthSquared < nearestLengthSquared:
				nearestLengthSquared = lengthSquared
				nearestID = dropID
	if nearestID > 0:
		Launcher.Network.PickupDrop(nearestID)
