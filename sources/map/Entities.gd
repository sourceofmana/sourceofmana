extends RefCounted
class_name Entities

#
static var entities : Dictionary[int, Entity]		= {}
static var target : Entity							= null
static var hovered : Entity							= null
static var hoveredInRange : bool					= false

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
	if not ActorCommons.IsAlive(target) or (not Launcher.GUI.IsDialogueContextOpened() and not Util.IsReachableSquared(Launcher.Player.position, target.position, ActorCommons.TargetMaxSquaredDistance)):
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

static func ClearHovered():
	hovered = null
	DeviceManager.ResetCursor()

static func RefreshHovered():
	if not hovered:
		return

	match hovered.type:
		ActorCommons.Type.PLAYER:
			hoveredInRange = false
		ActorCommons.Type.NPC:
			if ActorCommons.IsActorNear(Launcher.Player, hovered, ActorCommons.TargetMaxDistance):
				DeviceManager.SetCursor(DeviceManager.CursorType.INTERACT)
				hoveredInRange = true
			else:
				hoveredInRange = false
		ActorCommons.Type.MONSTER:
			var meleeSkill : SkillCell = DB.GetSkill(SkillCommons.SkillMeleeName.hash())
			if Launcher.Player.progress.HasSkill(meleeSkill) and ActorCommons.IsAlive(hovered) and ActorCommons.IsActorNear(Launcher.Player, hovered, ActorCommons.GetSkillRange(Launcher.Player, meleeSkill)):
				hoveredInRange = true
				DeviceManager.SetCursor(DeviceManager.CursorType.ATTACK)
			else:
				hoveredInRange = false
