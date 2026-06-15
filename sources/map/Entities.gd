extends RefCounted
class_name Entities

#
static var entities : Dictionary[int, Entity]		= {}
static var target : Entity							= null
static var hovered : Entity							= null

# Entities access
static func Get(agentRID : int) -> Entity:
	return entities.get(agentRID, null)

static func GetNamed(agentName : String) -> Entity:
	for entityIdx in entities:
		var entity : Entity = entities[entityIdx]
		if entity.nick == agentName:
			return entity
	return null

static func Clear():
	var currentPlayerAgentRID : int = Launcher.Player.agentRID if Launcher.Player else NetworkCommons.PeerUnknownID
	entities.clear()
	if currentPlayerAgentRID != NetworkCommons.PeerUnknownID:
		entities[currentPlayerAgentRID] = Launcher.Player

static func Add(entity : Entity, agentRID : int):
	entities[agentRID] = entity

static func Erase(agentRID : int):
	entities.erase(agentRID)

# Target
static func ClearTarget():
	if target != null:
		if target.interactive:
			target.interactive.DisplayTarget(ActorCommons.Target.NONE)
		if target.is_inside_tree():
			Callback.SelfDestructTimer(target.interactive.healthBar, ActorCommons.DisplayHPDelay, target.interactive.HideHP, [], "HideHP")
		else:
			target.interactive.HideHP()
		target = null

static func Target(source : Vector2, interactable : bool = true, nextTarget : bool = false):
	var newTarget : Entity = GetNextTarget(source, target if nextTarget and target != null else null, interactable)
	SetTarget(newTarget, interactable)

static func SetTarget(newTarget : Entity, interactable : bool = true):
	if newTarget != target:
		ClearTarget()
		target = newTarget

	if target:
		if interactable and target.type == ActorCommons.Type.NPC:
			target.interactive.DisplayTarget(ActorCommons.Target.ALLY)
		elif target.type == ActorCommons.Type.MONSTER:
			target.interactive.DisplayTarget(ActorCommons.Target.ENEMY)
			target.interactive.DisplayHP()
		Network.TriggerSelect(target.agentRID)

static func JustInteract():
	if not ActorCommons.IsAlive(target) or (not Launcher.GUI.IsDialogueContextOpened() and not ActorCommons.IsActorNear(Launcher.Player, target, ActorCommons.TargetMaxDistance)):
		Target(Launcher.Player.position, true)
	if target and target.type == ActorCommons.Type.NPC:
		if target.defaultState != ActorCommons.State.UNKNOWN and target.state != target.defaultState:
			ClearTarget()
	if target:
		if target.type == ActorCommons.Type.NPC:
			Network.TriggerInteract(target.agentRID)
			ClearTarget()
		else:
			Interact()
	elif Launcher.Player.stat.IsSailing():
		Launcher.Player.interactive.DisplaySailContext()

static func Interact():
	if target != null:
		if target.type == ActorCommons.Type.MONSTER:
			Launcher.Player.Cast(DB.GetCellHash(SkillCommons.SkillMeleeName))

static func GetNextTarget(source : Vector2, currentEntity : Entity, interactable : bool) -> Entity:
	var nearestDistance : float	= INF
	var minThreshold : float = 0
	var nextTarget : Entity = null
	if currentEntity:
		nearestDistance = source.distance_squared_to(currentEntity.position)
		minThreshold = nearestDistance
		nextTarget = currentEntity

	for entity in entities.values():
		if entity and entity != currentEntity:
			var isAliveMonster : bool = entity.type == ActorCommons.Type.MONSTER and entity.state != ActorCommons.State.DEATH
			var isNpc : bool = interactable and entity.type == ActorCommons.Type.NPC
			if isAliveMonster or isNpc:
				# If is in a different state than the overridden one
				if entity.defaultState != ActorCommons.State.UNKNOWN and entity.state != entity.defaultState:
					continue
				var entityData : EntityData = DB.EntitiesDB.get(entity.stat.currentShape, null)
				if entityData:
					# If the current quest state forbides the selection
					if entityData._questID != ProgressCommons.Quest.UNKNOWN:
						var questState : int = Launcher.Player.progress.GetQuest(entityData._questID) if Launcher.Player else ProgressCommons.UnknownProgress
						if entityData._questStateMax != ProgressCommons.UnknownProgress:
							if questState < entityData._questState or questState > entityData._questStateMax:
								continue
						else:
							if questState != entityData._questState:
								continue
				# If too far away
				var distance : float = source.distance_squared_to(entity.position)
				if distance > ActorCommons.TargetMaxSquaredDistance:
					continue

				if nearestDistance <= minThreshold:
					if distance < nearestDistance or distance > minThreshold:
						nearestDistance = distance
						nextTarget = entity
				else:
					if distance < nearestDistance and distance > minThreshold:
						nearestDistance = distance
						nextTarget = entity

	return nextTarget

# Hovered
static func SetHovered(nextHovered : Entity):
	hovered = nextHovered
	RefreshHovered()

static func ClearHovered():
	hovered = null
	DeviceManager.ResetCursor()

static func ClearDelayedHoveredCallback():
	Callback.RemoveMatchingCallback(Entities, Launcher.Map.PlayerHalted, InteractHovered)

static func RefreshHovered():
	if not hovered:
		return

	match hovered.type:
		ActorCommons.Type.PLAYER:
			pass
		ActorCommons.Type.NPC:
			DeviceManager.SetCursor(DeviceManager.CursorType.INTERACT)
		ActorCommons.Type.MONSTER:
			DeviceManager.SetCursor(DeviceManager.CursorType.ATTACK)

static func InteractHovered(targetHovered : Entity):
	if not targetHovered:
		return

	var moveToEntity : bool = false
	var walkToDistance : int = 0
	ClearDelayedHoveredCallback()

	match targetHovered.type:
		ActorCommons.Type.PLAYER:
			pass
		ActorCommons.Type.NPC:
			if ActorCommons.IsActorNear(Launcher.Player, targetHovered, ActorCommons.TargetWalkToDistance):
				Entities.SetTarget(targetHovered)
				Entities.JustInteract()
			else:
				moveToEntity = true
				walkToDistance = ActorCommons.TargetWalkToDistance
		ActorCommons.Type.MONSTER:
			var hoveredInRange : bool = ActorCommons.IsAlive(targetHovered) and ActorCommons.IsActorNear(Launcher.Player, targetHovered, Launcher.Player.stat.current.attackRange)
			if hoveredInRange:
				Entities.SetTarget(targetHovered)
				Entities.JustInteract()
			else:
				moveToEntity = true
				walkToDistance = Launcher.Player.stat.current.attackRange

	if moveToEntity:
		var playerPos : Vector2 = Launcher.Player.get_position()
		var targetPos : Vector2 = targetHovered.get_position()
		var targetPosition : Vector2 = playerPos + playerPos.direction_to(targetPos) * (playerPos.distance_to(targetPos) - walkToDistance)
		Launcher.Action.MoveTo(targetPosition)
		Launcher.Map.PlayerHalted.connect(InteractHovered.bind(targetHovered), ConnectFlags.CONNECT_ONE_SHOT)
