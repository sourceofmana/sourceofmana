extends Actor
class_name BaseEntity

#
@onready var interactive : EntityInteractive	= $Interactions

var displayName : bool					= false
var entityName : String					= ""

var gender : ActorCommons.Gender		= ActorCommons.Gender.MALE
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO
var entityOrientation : Vector2			= Vector2.ZERO

var visual : EntityVisual				= EntityVisual.new()
var agentID : int						= -1

signal entity_died

# Init
func SetData(data : EntityData):
	# Display
	displayName = displayName or data._displayName
	SetVisual(data)

func SetVisual(data : EntityData, morphed : bool = false):
	var visualInitCallback : Callable = visual.Init.bind(self, data)
	if morphed:
		interactive.DisplayMorph(visualInitCallback)
	else:
		visualInitCallback.call()

#
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextOrientation : Vector2, nextState : ActorCommons.State, nextSkillCastName : String):
	var dist = Vector2(gardbandPosition - position).length()
	if dist > NetworkCommons.MaxGuardbandDist:
		position = gardbandPosition

	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	var previousState = state
	state = nextState
	entityOrientation = nextOrientation

	if visual and interactive and visual.skillCastName != nextSkillCastName:
		visual.skillCastName = nextSkillCastName
		interactive.DisplayCast(self, nextSkillCastName)

	if previousState != nextState and nextState == ActorCommons.State.DEATH:
		entity_died.emit()

#
func _physics_process(delta):
	velocity = entityVelocity

	if entityPosOffset.length() > NetworkCommons.StartGuardbandDist:
		var posOffsetFix : Vector2 = entityPosOffset * NetworkCommons.PatchGuardband * delta
		entityPosOffset -= posOffsetFix * delta
		velocity += posOffsetFix

	if velocity != Vector2.ZERO:
		move_and_slide()

func _process(delta : float):
	visual.Refresh(delta)

func _ready():
	if Launcher.Player != self:
		stat.active_stats_updated.connect(interactive.DisplayHP)
