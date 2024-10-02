extends Actor
class_name Entity

#
@onready var interactive : EntityInteractive	= $Interactive
@onready var visual : EntityVisual				= $Visual

var target : Entity						= null

var gender : ActorCommons.Gender		= ActorCommons.Gender.MALE
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO
var entityOrientation : Vector2			= Vector2.ZERO

var agentID : int						= -1

signal entity_died

# Init
func SetData():
	SetVisual(data)
	interactive.Init(data)

func SetVisual(altData : EntityData, morphed : bool = false):
	if morphed:
		interactive.DisplayMorph(visual.Init, [altData])
	else:
		visual.Init(altData)

#
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextOrientation : Vector2, nextState : ActorCommons.State, nextskillCastID : int, forceValue : bool = false):
	var dist = Vector2(gardbandPosition - position).length_squared()
	if dist > NetworkCommons.MaxGuardbandDistSquared or forceValue:
		position = gardbandPosition

	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	var previousState = state
	state = nextState
	entityOrientation = nextOrientation

	if visual and visual.skillCastID != nextskillCastID:
		visual.skillCastID = nextskillCastID
		interactive.DisplayCast(self, nextskillCastID)

	if previousState != nextState and nextState == ActorCommons.State.DEATH:
		entity_died.emit()

# Local player specific functions
func SetLocalPlayer():
	collision_layer |= 2

	if Launcher.Camera:
		Launcher.Camera.mainCamera = FileSystem.LoadEntityComponent("Camera")
		if Launcher.Camera.mainCamera:
			add_child.call_deferred(Launcher.Camera.mainCamera)
	
	entity_died.connect(Launcher.GUI.respawnWindow.EnableControl.bind(true))
	Launcher.Network.RetrieveInventory()
	Launcher.FSM.EnterState(Launcher.FSM.States.IN_GAME)

func ClearTarget():
	if target != null:
		if target.interactive.nameLabel.material:
			target.interactive.nameLabel.material = null
		if target.is_inside_tree():
			Callback.SelfDestructTimer(target.interactive.healthBar, ActorCommons.DisplayHPDelay, target.interactive.HideHP, [], "HideHP")
		else:
			target.interactive.HideHP()
		target = null

func Target(source : Vector2, interactable : bool = true, nextTarget : bool = false):
	var newTarget = Entities.GetNextTarget(source, target if nextTarget and target != null else null, interactable)
	if newTarget != target:
		ClearTarget()
		target = newTarget

	if target:
		if interactable and target.type == ActorCommons.Type.NPC:
			target.interactive.nameLabel.material = ActorCommons.AllyTarget
		elif target.type == ActorCommons.Type.MONSTER:
			target.interactive.nameLabel.material = ActorCommons.EnemyTarget
			Launcher.Network.TriggerSelect(target.agentID)

func JustInteract():
	if not target or target.state == ActorCommons.State.DEATH:
		Target(position, true)
	if target:
		Interact()
	else:
		if stat.IsSailing():
			interactive.DisplaySailContext()

func Interact():
	if target != null:
		if target.type == ActorCommons.Type.NPC:
			Launcher.Network.TriggerInteract(target.agentID)
		elif target.type == ActorCommons.Type.MONSTER:
			Cast(DB.GetCellHash(SkillCommons.SkillMeleeName))

func Cast(skillID : int):
	var skill : SkillCell = DB.SkillsDB[skillID]
	assert(skill != null, "Skill ID is not found, can't cast it")
	if skill == null:
		return

	var entityID : int = 0
	if skill.mode == Skill.TargetMode.SINGLE:
		if not target or target.state == ActorCommons.State.DEATH or target.type != ActorCommons.Type.MONSTER:
			Target(position, false)
		if target and target.type == ActorCommons.Type.MONSTER:
			entityID = target.agentID

	Launcher.Network.TriggerCast(entityID, skillID)

#
func _physics_process(delta : float):
	velocity = entityVelocity

	if entityPosOffset.length_squared() > NetworkCommons.StartGuardbandDistSquared and delta > 0:
		var signOffset = sign(entityPosOffset)
		var posOffsetFix : Vector2 = stat.current.walkSpeed * 0.5 * delta * signOffset
		entityPosOffset.x = max(0, entityPosOffset.x - posOffsetFix.x) if signOffset.x > 0 else min(0, entityPosOffset.x - posOffsetFix.x)
		entityPosOffset.y = max(0, entityPosOffset.y - posOffsetFix.y) if signOffset.y > 0 else min(0, entityPosOffset.y - posOffsetFix.y)
		velocity += posOffsetFix / delta

	if velocity != Vector2.ZERO:
		move_and_slide()

func _ready():
	if Launcher.Player == self:
		Launcher.Map.MapUnloaded.connect(ClearTarget)
	else:
		stat.active_stats_updated.connect(interactive.DisplayHP)
	entity_died.connect(interactive.DisplayHP)
