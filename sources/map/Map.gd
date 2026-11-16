extends ServiceBase
class_name MapService

#
signal MapUnloaded
signal MapLoaded
signal PlayerWarped
signal PlayerMoved
signal PlayerHalted

#
var pool : MapPool						= MapPool.new()
var currentMapID : int					= DB.UnknownHash
var currentMapNode : Node2D				= null
var currentFringe : TileMapLayer		= null
var drops : Dictionary[int, Sprite2D]	= {}
var hoveredDrop : int					= -1
var entityCache : Dictionary[int, EntityCacheEntry] = {}
var pendingEntities : Array[Entity]		= []
var pendingWarp : bool					= true

# Map Scenes
func RefreshTileMap():
	for child in currentMapNode.get_children():
		if child is TileMapLayer and child.name == "Fringe":
			currentFringe = child
			break

func GetMapBoundaries() -> Vector2:
	assert(currentMapNode != null, "Map node not found on the current scene")
	return currentMapNode.get_meta("MapBoundaries", Vector2.ZERO) if currentMapNode else Vector2.ZERO

func EmplaceMapNode(mapID : int, force : bool = false):
	if not force and currentMapID == mapID:
		ClearEntities()
		return

	UnloadMapNode()
	LoadMapNode(mapID)

func UnloadMapNode():
	if currentMapNode:
		RemoveChildren()
		pendingEntities.clear()
		Launcher.remove_child(currentMapNode)
		currentMapID = DB.UnknownHash
		currentMapNode = null
		currentFringe = null
		drops.clear()
		ClearHoveredDrop()
		pendingWarp = true
		entityCache.clear()
		Entities.Clear()
		MapUnloaded.emit()

func LoadMapNode(mapID : int):
	currentMapNode = pool.LoadMapLayers(mapID)
	currentMapID = mapID
	assert(currentMapNode != null, "Map instance could not be created")
	if currentMapNode:
		RefreshTileMap()
		Launcher.add_child(currentMapNode)
		MapLoaded.emit()

func RefreshPool(preloadAdjacentMaps : bool):
	if not currentMapNode:
		return
	var adjacentMaps : PackedInt64Array = []
	var mapData : MapData = DB.MapsDB.get(currentMapID, null)
	var isPoolAllowed : bool = mapData != null and not mapData.HasFlags(WorldMap.Flags.NO_MAP_POOL)
	if preloadAdjacentMaps and LauncherCommons.EnableMapPool and isPoolAllowed:
		adjacentMaps = currentMapNode.get_meta("AdjacentMapIDs", adjacentMaps)
	pool.Refresh(currentMapID, adjacentMaps)

func ClearEntities():
	Entities.ClearTarget()
	Entities.ClearHovered()
	for entity in Entities.entities.values():
		if entity != Launcher.Player:
			RemoveChild(entity)
	entityCache.clear()
	Entities.Clear()

# Entity cache
func PreloadEntity(agentRID : int, actorType : ActorCommons.Type, currentShape : int, nick : String, defaultState : ActorCommons.State):
	var entry : EntityCacheEntry = EntityCacheEntry.new()
	entry.actorType = actorType
	entry.currentShape = currentShape
	entry.nick = nick
	entry.defaultState = defaultState
	entityCache[agentRID] = entry

func PreloadPlayer(agentRID : int, spirit : int, currentShape : int, nick : String, level : int, health : int, hairstyle : int, haircolor : int, gender : int, race : int, skintone : int, equipment : Dictionary):
	var entry : EntityCacheEntry = EntityCacheEntry.new()
	entry.actorType = ActorCommons.Type.PLAYER
	entry.spirit = spirit
	entry.currentShape = currentShape
	entry.nick = nick
	entry.level = level
	entry.health = health
	entry.hairstyle = hairstyle
	entry.haircolor = haircolor
	entry.gender = gender
	entry.race = race
	entry.skintone = skintone
	entry.equipment = equipment
	entityCache[agentRID] = entry

func SpawnEntity(agentRID : int, entry : EntityCacheEntry) -> Entity:
	if not currentFringe:
		return null

	var shape : int = ActorCommons.PlayerEntityID if entry.actorType == ActorCommons.Type.PLAYER else entry.currentShape
	var entityData : EntityData = DB.EntitiesDB.get(shape, null)
	if not entityData:
		return null

	var isPlayerType : bool = entry.actorType == ActorCommons.Type.PLAYER
	var isLocalPlayer : bool = isPlayerType and entry.nick == Launcher.GUI.characterPanel.characterNameDisplay.get_text()

	var entity : Entity = Instantiate.CreateEntity(entry.actorType, entityData, entityData._name if entry.nick.is_empty() else entry.nick, isLocalPlayer)
	entity.agentRID = agentRID
	entity.defaultState = entry.defaultState
	entity.stat.shape = shape
	entity.stat.spirit = entry.spirit
	entity.stat.currentShape = entry.currentShape

	if isPlayerType:
		entity.stat.level = entry.level
		entity.stat.health = entry.health
		entity.stat.hairstyle = entry.hairstyle
		entity.stat.haircolor = entry.haircolor
		entity.stat.gender = entry.gender
		entity.stat.race = entry.race
		entity.stat.skintone = entry.skintone
		if entity.inventory and not entry.equipment.is_empty():
			entity.inventory.ImportEquipment(entry.equipment)

	if isLocalPlayer:
		Launcher.Player = entity
		Launcher.Player.SetLocalPlayer()
		Monitoring.SetPlayer(entry.nick)
		pendingWarp = false
		AddChild(entity)
	else:
		pendingEntities.push_back(entity)
	Entities.Add(entity, agentRID)

	if isLocalPlayer:
		PlayerWarped.emit()

	return entity

# Generic fringe Node2D
func RemoveChildren():
	for entity in Entities.entities.values():
		RemoveChild(entity)
	for drop in drops.values():
		RemoveChild(drop)

func RemoveChild(child : Node2D):
	if child:
		if child is Entity:
			pendingEntities.erase(child)
		if currentFringe and child.get_parent() == currentFringe:
			currentFringe.remove_child.call_deferred(child)
		if child != Launcher.Player:
			child.queue_free()

func AddChild(child : Node2D):
	assert(currentFringe != null, "Current fringe layer not found, could not add a new child")
	if currentFringe:
		currentFringe.add_child.call_deferred(child)

func AddPendingEntities():
	if pendingEntities.is_empty() or not currentFringe:
		return

	if Launcher.Player and pendingEntities.size() > 1:
		var origin : Vector2 = Launcher.Player.position
		pendingEntities.sort_custom(func(a : Entity, b : Entity): return a.position.distance_squared_to(origin) < b.position.distance_squared_to(origin))

	var deadlineMs : int = Time.get_ticks_msec() + LauncherCommons.EntitySpawnBudgetPerFrameMs
	while not pendingEntities.is_empty():
		currentFringe.add_child(pendingEntities.pop_front())
		if Time.get_ticks_msec() >= deadlineMs:
			break

# Entities
func FullUpdateEntity(agentRID : int, agentVelocity : Vector2, agentPosition : Vector2, agentOrientation : Vector2, agentState : ActorCommons.State, skillCastID : int, isRunning : bool, frameID : int):
	if not currentFringe:
		return

	var entity : Entity = Entities.Get(agentRID)
	var isNewSpawn : bool = false
	if entity == null:
		var entry : EntityCacheEntry = entityCache.get(agentRID, null)
		if entry:
			entity = SpawnEntity(agentRID, entry)
			isNewSpawn = true
	elif entity == Launcher.Player:
		if pendingWarp:
			pendingWarp = false
			isNewSpawn = entity.get_parent() != currentFringe
			entity.RefreshData.call_deferred()
			if isNewSpawn:
				AddChild(entity)
				PlayerWarped.emit.call_deferred()

	if entity:
		if NetworkCommons.IsFrameNewer(frameID, entity.lastUpdateFrameID):
			entity.lastUpdateFrameID = frameID
		entity.Update(agentVelocity, agentPosition, agentOrientation, agentState, skillCastID, isNewSpawn, isRunning)

func UpdateEntity(agentRID : int, agentVelocity : Vector2, agentPosition : Vector2, frameID : int):
	var entity : Entity = Entities.Get(agentRID)
	if entity and entity.visual:
		if not NetworkCommons.IsFrameNewer(frameID, entity.lastUpdateFrameID):
			return
		entity.lastUpdateFrameID = frameID
		var agentOrientation : Vector2 = entity.entityOrientation if agentVelocity.is_zero_approx() else agentVelocity.normalized()
		entity.Update(agentVelocity, agentPosition, agentOrientation, entity.state, entity.visual.skillCastID, false, entity.stat.isRunning)

func RemoveEntity(agentRID : int):
	var entity : Entity = Entities.Get(agentRID)
	if entity:
		if Entities.target == entity:
			Entities.target = null
		RemoveChild(entity)
		Entities.Erase(agentRID)

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
			var clickArea : Area2D = dropNode.get_node("ClickArea")
			clickArea.mouse_entered.connect(SetHoveredDrop.bind(dropID))
			clickArea.mouse_exited.connect(ClearHoveredDrop.bind(dropID))

func RemoveDrop(dropID : int):
	var drop : Sprite2D = drops.get(dropID)
	if drop:
		RemoveChild(drop)
		drops.erase(dropID)
		ClearHoveredDrop(dropID)

func SetHoveredDrop(dropID : int):
	hoveredDrop = dropID
	DeviceManager.SetCursor(DeviceManager.CursorType.PICKUP)

func ClearHoveredDrop(dropID : int = -1):
	if dropID == -1 or hoveredDrop == dropID:
		hoveredDrop = -1
		DeviceManager.ResetCursor()

func ClearDelayedPickupCallback():
	Callback.RemoveMatchingCallback(self, PlayerHalted, PickupHoveredDrop)

func PickupHoveredDrop(dropID : int):
	ClearDelayedPickupCallback()
	if not Launcher.Player:
		return

	var drop : Sprite2D = drops.get(dropID)
	if not drop:
		return

	if Launcher.Player.position.distance_squared_to(drop.position) < ActorCommons.PickupSquaredDistance:
		Network.PickupDrop(dropID)
	else:
		Launcher.Action.MoveTo(drop.position)
		PlayerHalted.connect(PickupHoveredDrop.bind(dropID), ConnectFlags.CONNECT_ONE_SHOT)

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
func Tick():
	pool.Poll()
	AddPendingEntities()

func _post_launch():
	isInitialized = true
	FSM.exit_game.connect(LeaveGame)
	Launcher.get_tree().process_frame.connect(Tick)

func Destroy():
	LeaveGame()
	if Launcher.get_tree().process_frame.is_connected(Tick):
		Launcher.get_tree().process_frame.disconnect(Tick)
	pool.Clear()
