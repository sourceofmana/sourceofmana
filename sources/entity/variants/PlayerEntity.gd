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
	
	entity_died.connect(Launcher.GUI.respawnWindow.EnableControl.bind(true))

func ClearTarget():
	if target != null:
		if target.visual.sprites[EntityCommons.Slot.BODY].material:
			target.visual.sprites[EntityCommons.Slot.BODY].material = null
		target = null

func Target(source : Vector2, interactable : bool = true):
	if not interactive:
		return

	ClearTarget()
	target = Entities.GetNearestTarget(source, interactable)

	if target:
		if interactable and target is NpcEntity:
			target.visual.SetMainMaterial.call_deferred(EntityCommons.AllyTarget)
		elif target is MonsterEntity:
			target.visual.SetMainMaterial.call_deferred(EntityCommons.EnemyTarget)
			Launcher.Network.TriggerSelect(target.agentID)

func Interact():
	if not target or target.entityState == EntityCommons.State.DEATH:
		Target(position, true)
	if not target:
		return

	if target is NpcEntity:
		Launcher.Network.TriggerInteract(target.agentID)
	elif target is MonsterEntity:
		Cast("Melee")

func Cast(skillName : String):
	var skill : SkillData = DB.SkillsDB[skillName]
	Util.Assert(skill != null, "Skill ID is not found, can't cast it")
	if skill == null:
		return

	var entityID : int = 0
	if skill._mode == Skill.TargetMode.SINGLE:
		if not target or target.entityState == EntityCommons.State.DEATH:
			Target(position, false)
		if target and target is MonsterEntity:
			entityID = target.agentID

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
