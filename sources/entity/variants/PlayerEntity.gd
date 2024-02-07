extends BaseEntity
class_name PlayerEntity

#
var target : BaseEntity					= null

#
func SetLocalPlayer():
	collision_layer |= 2

	if Launcher.Camera:
		Launcher.Camera.mainCamera = FileSystem.LoadEntityComponent("Camera")
		if Launcher.Camera.mainCamera:
			add_child.call_deferred(Launcher.Camera.mainCamera)
	
	entity_died.connect(func (): Launcher.GUI.respawnWindow.EnableControl(true))

func ClearTarget():
	if target != null:
		if target.visual.sprites[EntityCommons.Slot.BODY].material:
			target.visual.sprites[EntityCommons.Slot.BODY].material = null
		target = null

func Target(pos : Vector2, canInteract : bool = true):
	if not interactive:
		return

	var nearestDistance : float = -1

	ClearTarget()
	for entityID in Launcher.Map.entities:
		var entity : BaseEntity = Launcher.Map.entities[entityID]
		if entity and entity.entityState != EntityCommons.State.DEATH:
			if entity is MonsterEntity or (canInteract and entity is NpcEntity):
				var distance : float = (entity.position - pos).length()
				if nearestDistance == -1 or distance < nearestDistance:
					nearestDistance = distance
					target = entity

	if target:
		if canInteract and target is NpcEntity:
			target.visual.SetMainMaterial.call_deferred(EntityCommons.AllyTarget)
		elif target is MonsterEntity:
			target.visual.SetMainMaterial.call_deferred(EntityCommons.EnemyTarget)


func Interact():
	if not target or target.entityState == EntityCommons.State.DEATH:
		Target(position, true)
	if not target:
		return

	if target is NpcEntity:
		Launcher.Network.TriggerInteract(Launcher.Map.entities.find_key(target))
	elif target is MonsterEntity:
		Cast("Melee")

func Cast(skillName : String):
	var skill : SkillData = Launcher.DB.SkillsDB[skillName]
	Util.Assert(skill != null, "Skill ID is not found, can't cast it")
	if skill == null:
		return

	var entityID : int = 0
	if skill._mode == Skill.TargetMode.SINGLE:
		if not target or target.entityState == EntityCommons.State.DEATH:
			Target(position, false)
		if target and target is MonsterEntity:
			entityID = Launcher.Map.entities.find_key(target)

	Launcher.Network.TriggerCast(entityID, skillName)

#
func _process(deltaTime : float):
	super._process(deltaTime)

	if Launcher.Debug and Launcher.Player == self:
		if Launcher.Debug.correctPos:
			Launcher.Debug.correctPos.position = position + entityPosOffset
		if Launcher.Debug.wrongPos:
			Launcher.Debug.wrongPos.position = position

func _init():
	displayName = true
