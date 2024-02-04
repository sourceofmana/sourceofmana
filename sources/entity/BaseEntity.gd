extends CharacterBody2D
class_name BaseEntity

#
@onready var interactive : EntityInteractive	= $Interactions

var displayName : bool					= false
var entityName : String					= ""

var entityState : EntityCommons.State	= EntityCommons.State.IDLE
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO
var entityOrientation : Vector2			= Vector2.ZERO

var inventory : EntityInventory			= EntityInventory.new()
var stat : EntityStats					= EntityStats.new()
var visual : EntityVisual				= EntityVisual.new()

# Init
func SetData(data : EntityData):
	# Stat
	if data._stats:
		stat.Init(data)

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
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextOrientation : Vector2, nextState : EntityCommons.State, nextSkillCastName : String):
	var dist = Vector2(gardbandPosition - position).length()
	if dist > EntityCommons.MaxGuardbandDist:
		position = gardbandPosition

	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	entityState = nextState
	entityOrientation = nextOrientation

	if visual.skillCastName != nextSkillCastName:
		visual.skillCastName = nextSkillCastName
		interactive.DisplayCast(self, nextSkillCastName)

#
func _physics_process(delta):
	velocity = entityVelocity

	if entityPosOffset.length() > EntityCommons.StartGuardbandDist:
		var posOffsetFix : Vector2 = entityPosOffset * EntityCommons.PatchGuardband * delta
		entityPosOffset -= posOffsetFix * delta
		velocity += posOffsetFix

	if velocity != Vector2.ZERO:
		move_and_slide()

func _process(delta : float):
	visual.Refresh(delta)
