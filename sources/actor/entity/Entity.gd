extends Actor
class_name Entity

#
@onready var interactive : EntityInteractive	= $Interactive
@onready var visual : EntityVisual				= $Visual

var target : Entity						= null

var gender : ActorCommons.Gender		= ActorCommons.Gender.MALE
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO
var entityOrientation : Vector2			= Vector2(0, 1)

var agentRID : int						= -1

signal entity_died

# Init
func SetData():
	var altData : EntityData = null
	var isMorph : bool = stat.IsMorph()
	if isMorph:
		altData = DB.EntitiesDB.get(stat.currentShape, null)
	SetVisual(altData if altData else data)
	interactive.Init(altData if altData else data)

func SetVisual(altData : EntityData, morphed : bool = false):
	if morphed:
		interactive.DisplayMorph(visual.Init, [altData])
	else:
		visual.Init(altData)

#
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextOrientation : Vector2, nextState : ActorCommons.State, nextskillCastID : int, forceValue : bool = false):
	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	var previousState = state
	state = nextState
	if nextOrientation != Vector2.ZERO:
		entityOrientation = nextOrientation

	var dist = Vector2(entityPosOffset).length_squared()
	if dist > NetworkCommons.MaxGuardbandDistSquared or forceValue:
		position = gardbandPosition
		entityPosOffset = Vector2.ZERO
		if Launcher.Player == self:
			Launcher.Map.PlayerMoved.emit()

	if visual and visual.skillCastID != nextskillCastID:
		visual.skillCastID = nextskillCastID
		interactive.DisplayCast(self, nextskillCastID)

	if previousState != nextState and nextState == ActorCommons.State.DEATH:
		entity_died.emit()

# Local player specific functions
func SetLocalPlayer():
	collision_layer |= 2

	if Launcher.Camera and Launcher.Camera.mainCamera:
		var remotePos : RemoteTransform2D = RemoteTransform2D.new()
		add_child.call_deferred(remotePos)
		remotePos.set_remote_node(Launcher.Camera.mainCamera.get_path())
		Launcher.Camera.mainCamera.make_current()

	entity_died.connect(Launcher.GUI.respawnWindow.EnableControl.bind(true))
	Network.RetrieveCharacterInformation()
	FSM.EnterState(FSM.States.IN_GAME)

func ClearTarget():
	if target != null:
		if target.interactive:
			target.interactive.DisplayTarget(ActorCommons.Target.NONE)
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
			target.interactive.DisplayTarget(ActorCommons.Target.ALLY)
		elif target.type == ActorCommons.Type.MONSTER:
			target.interactive.DisplayTarget(ActorCommons.Target.ENEMY)
			target.interactive.DisplayHP()
		Network.TriggerSelect(target.agentRID)

func JustInteract():
	if not ActorCommons.IsAlive(target) or (not Launcher.GUI.IsDialogueContextOpened() and Util.IsReachableSquared(position, target.position, ActorCommons.TargetMaxSquaredDistance)):
		Target(position, true)
	if target:
		Interact()
	elif stat.IsSailing():
		interactive.DisplaySailContext()

func Interact():
	if target != null:
		if target.type == ActorCommons.Type.NPC:
			Network.TriggerInteract(target.agentRID)
		elif target.type == ActorCommons.Type.MONSTER:
			Cast(DB.GetCellHash(SkillCommons.SkillMeleeName))

func Cast(skillID : int):
	if Launcher.GUI.IsDialogueContextOpened():
		return

	assert(skillID in DB.SkillsDB, "Skill ID %x not found within our skill db" % skillID)
	if not skillID in DB.SkillsDB:
		return

	var skill : SkillCell = DB.SkillsDB[skillID]
	assert(skill != null, "Skill ID is not found, can't cast it")
	if skill == null:
		return

	var targetRID : int = 0
	if skill.mode == Skill.TargetMode.SINGLE:
		if not target or target.state == ActorCommons.State.DEATH or target.type != ActorCommons.Type.MONSTER:
			Target(position, false)
		if target and target.type == ActorCommons.Type.MONSTER:
			targetRID = target.agentRID

	Network.TriggerCast(targetRID, skillID)

func LevelUp():
	if Launcher.Player == self:
		Network.PushNotification("Level %d reached.\nFeel the mana power growing inside you!" % (stat.level))

	stat.RefreshAttributes()
	if interactive:
		interactive.DisplayLevelUp.call_deferred()

#
func _physics_process(delta : float):
	var totalVelocity : Vector2 = entityVelocity + entityPosOffset / delta
	velocity = totalVelocity.limit_length(stat.current.walkSpeed)
	if velocity != Vector2.ZERO:
		var extraVelocity : Vector2 = velocity - entityVelocity
		entityPosOffset -= extraVelocity * delta
		move_and_slide()
		if Launcher.Player == self:
			Launcher.Map.PlayerMoved.emit()

func _ready():
	if Launcher.Player == self:
		Launcher.Map.MapUnloaded.connect(ClearTarget)
	elif type == ActorCommons.Type.MONSTER:
		stat.vital_stats_updated.connect(interactive.RefreshHP)

	entity_died.connect(interactive.HideHP)
	entity_died.connect(interactive.DisplayTarget.bind(ActorCommons.Target.NONE))
