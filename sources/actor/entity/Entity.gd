extends Actor
class_name Entity

#
@onready var interactive : EntityInteractive	= $Interactive
@onready var visual : EntityVisual				= $Visual
@onready var sfx : EntitySfx					= $Sfx

var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO
var entityOrientation : Vector2			= Vector2(0, 1)

var agentRID : int						= DB.UnknownHash
var defaultState : ActorCommons.State	= ActorCommons.State.UNKNOWN

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
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextOrientation : Vector2, nextState : ActorCommons.State, nextskillCastID : int, forceValue : bool = false, isRunning : bool = false):
	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	var previousState = state
	state = nextState
	if nextOrientation != Vector2.ZERO:
		entityOrientation = nextOrientation

	if forceValue or Vector2(entityPosOffset).length_squared() > NetworkCommons.MaxGuardbandDistSquared:
		position = gardbandPosition
		entityPosOffset = Vector2.ZERO
		if Launcher.Player == self:
			Launcher.Map.PlayerMoved.emit()

	if isRunning != stat.isRunning:
		stat.isRunning = isRunning
		stat.RefreshEntityStats()

	if visual:
		if visual.skillCastID != nextskillCastID:
			visual.skillCastID = nextskillCastID
			interactive.DisplayCast(nextskillCastID)
		visual.Refresh()

	if previousState != nextState:
		if sfx:
			sfx.HandleState(nextState)

		match nextState:
			ActorCommons.State.DEATH:
				entity_died.emit()
			ActorCommons.State.IDLE:
				if Launcher.Player == self:
					Launcher.Map.PlayerHalted.emit()

	set_physics_process(true)

# Local player specific functions
func SetLocalPlayer():
	if Launcher.Camera and Launcher.Camera.camera:
		Launcher.Camera.remoteTransform = RemoteTransform2D.new()
		add_child.call_deferred(Launcher.Camera.remoteTransform)
		Launcher.Camera.remoteTransform.set_remote_node(Launcher.Camera.camera.get_path())
		Launcher.Camera.camera.make_current()

	entity_died.connect(Launcher.GUI.respawnWindow.EnableControl.bind(true))
	Network.RetrieveCharacterInformation()
	FSM.EnterState(FSM.States.IN_GAME)

func Cast(skillID : int):
	if Launcher.GUI.IsDialogueContextOpened():
		return

	assert(skillID in DB.SkillsDB, "Skill ID %x not found within our skill db" % skillID)
	if not skillID in DB.SkillsDB:
		return

	var skill : SkillCell = DB.SkillsDB[skillID]
	assert(skill != null, "Skill ID is not found, can't cast it")
	if skill == null or not skill.usable:
		return

	var targetRID : int = 0
	if skill.mode == Skill.TargetMode.SINGLE:
		if not Entities.target or Entities.target.state == ActorCommons.State.DEATH or Entities.target.type != ActorCommons.Type.MONSTER:
			Entities.Target(position, false)
		if Entities.target and Entities.target.type == ActorCommons.Type.MONSTER:
			targetRID = Entities.target.agentRID

	Network.TriggerSkill(targetRID, skillID)

func Run(shouldRun : bool):
	if shouldRun != stat.isRunning:
		Network.TriggerSkill(DB.UnknownHash, DB.GetCellHash("Run"))

func LevelUp():
	if Launcher.Player == self:
		Network.PushNotification("Level %d reached.\nFeel the mana power growing inside you!" % (stat.level))

	stat.RefreshAttributes()
	if interactive:
		interactive.DisplayLevelUp.call_deferred()
	if sfx:
		sfx.HandleAlteration(ActorCommons.Alteration.LVL_UP)

#
func _physics_process(delta : float):
	var previousVelocity : Vector2 = velocity
	velocity = entityVelocity + entityPosOffset / delta
	if velocity != Vector2.ZERO:
		var extraVelocity : Vector2 = velocity - entityVelocity
		entityPosOffset -= extraVelocity * delta
		move_and_slide()
		if Launcher.Player == self:
			Launcher.Map.PlayerMoved.emit()
	else:
		if Launcher.Player == self:
			if not previousVelocity.is_zero_approx():
				Launcher.Map.PlayerHalted.emit()
		set_physics_process(false)

func _ready():
	if Launcher.Player == self:
		if not Launcher.Map.MapUnloaded.is_connected(Entities.ClearTarget):
			Launcher.Map.MapUnloaded.connect(Entities.ClearTarget)
		if not Launcher.Map.PlayerWarped.is_connected(Entities.ClearHovered):
			Launcher.Map.PlayerWarped.connect(Entities.ClearHovered)

	elif type == ActorCommons.Type.MONSTER:
		if not stat.vital_stats_updated.is_connected(interactive.RefreshHP):
			stat.vital_stats_updated.connect(interactive.RefreshHP)
		if data._isBoss:
			stat.vital_stats_updated.connect(Launcher.GUI.bossTracker.OnStatsUpdated.bind(agentRID))
	else:
		if stat.vital_stats_updated.is_connected(interactive.RefreshHP):
			stat.vital_stats_updated.disconnect(interactive.RefreshHP)

	if not entity_died.is_connected(interactive.HideHP):
		entity_died.connect(interactive.HideHP)
	var displayTargetNone : Callable = interactive.DisplayTarget.bind(ActorCommons.Target.NONE)
	if not entity_died.is_connected(displayTargetNone):
		entity_died.connect(displayTargetNone)

	if sfx and not visual.state_changed.is_connected(sfx.HandleState):
		visual.state_changed.connect(sfx.HandleState)
