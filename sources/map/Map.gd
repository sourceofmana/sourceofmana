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
var entityCache : Dictionary[int, EntityCacheEntry] = {}
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
		return

	UnloadMapNode()
	LoadMapNode(mapID)

	if LauncherCommons.EnableMapPool:
		pool.RefreshPool()

func UnloadMapNode():
	if currentMapNode:
		RemoveChildren()
		Launcher.remove_child(currentMapNode)
		currentMapID = DB.UnknownHash
		currentMapNode = null
		currentFringe = null
		drops.clear()
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

# Entity cache
func PreloadEntity(agentRID : int, actorType : ActorCommons.Type, currentShape : int, nick : String):
	var entry : EntityCacheEntry = EntityCacheEntry.new()
	entry.actorType = actorType
	entry.currentShape = currentShape
	entry.nick = nick
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

	AddChild(entity)
	if entry.currentShape != shape:
		entity.SetData.call_deferred()
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
		if currentFringe and child.get_parent() == currentFringe:
			currentFringe.remove_child.call_deferred(child)
		if child != Launcher.Player:
			child.queue_free()

func AddChild(child : Node2D):
	assert(currentFringe != null, "Current fringe layer not found, could not add a new child")
	if currentFringe:
		currentFringe.add_child.call_deferred(child)

# Entities
func FullUpdateEntity(agentRID : int, agentVelocity : Vector2, agentPosition : Vector2, agentOrientation : Vector2, agentState : ActorCommons.State, skillCastID : int, isRunning : bool):
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
			entity.SetData()
			if isNewSpawn:
				AddChild(entity)
			PlayerWarped.emit()

	if entity:
		entity.Update(agentVelocity, agentPosition, agentOrientation, agentState, skillCastID, isNewSpawn, isRunning)

func UpdateEntity(agentRID : int, agentVelocity : Vector2, agentPosition : Vector2):
	var entity : Entity = Entities.Get(agentRID)
	if entity and entity.visual:
		var agentOrientation : Vector2 = entity.entityOrientation if agentVelocity.is_zero_approx() else agentVelocity.normalized()
		entity.Update(agentVelocity, agentPosition, agentOrientation, entity.state, entity.visual.skillCastID, false, entity.stat.isRunning)

func RemoveEntity(agentRID : int):
	var entity : Entity = Entities.Get(agentRID)
	if entity:
		if Launcher.Player and Launcher.Player.target == entity:
			Launcher.Player.target = null
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
