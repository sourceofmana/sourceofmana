extends KinematicBody2D

onready var animationTree		= $AnimationTree
onready var animationState		= animationTree.get("parameters/playback")

var stat						= preload("res://sources/entity/Stat.gd").new()
var slot						= preload("res://sources/entity/Slot.gd").new()

var entityName					= ""
var showName					= false
var gender						= Trait.Gender.MALE
var damageReceived				= {}

var currentInput				= Vector2.ZERO
var currentVelocity				= Vector2.ZERO
var currentDirection			= Vector2.ZERO

var currentState				= Actions.State.IDLE
var currentStateTimer			= 0.0


#
func GetNextDirection():
	if currentVelocity.length_squared() > 1:
		return currentVelocity.normalized()
	else:
		return currentDirection

func GetNextState():
	var newEnumState			= currentState
	var isWalking				= currentVelocity.length_squared() > 1
	var actionSitPressed		= Input.is_action_pressed(Actions.ACTION_GP_SIT)
	var actionSitJustPressed	= Input.is_action_just_pressed(Actions.ACTION_GP_SIT)

	match currentState:
		Actions.State.IDLE:
			if isWalking:
				newEnumState = Actions.State.WALK
			elif actionSitJustPressed:
				newEnumState = Actions.State.SIT
		Actions.State.WALK:
			if isWalking == false:
				newEnumState = Actions.State.IDLE
		Actions.State.SIT:
			if actionSitPressed == false && isWalking:
				newEnumState = Actions.State.WALK
			elif actionSitJustPressed:
				newEnumState = Actions.State.IDLE

	return newEnumState

func ApplyNextState(nextState, nextDirection):
	currentState		= nextState
	currentDirection	= nextDirection

	animationTree.set("parameters/Idle/blend_position", currentDirection)
	animationTree.set("parameters/Sit/blend_position", currentDirection)
	animationTree.set("parameters/Walk/blend_position", currentDirection)

	match currentState:
		Actions.State.IDLE:
			animationState.travel("Idle")
		Actions.State.WALK:
			animationState.travel("Walk")
		Actions.State.SIT:
			animationState.travel("Sit")

#
func UpdateInput():
	currentInput.x	= Input.get_action_strength(Actions.ACTION_GP_MOVE_RIGHT) - Input.get_action_strength(Actions.ACTION_GP_MOVE_LEFT)
	currentInput.y	= Input.get_action_strength(Actions.ACTION_GP_MOVE_DOWN) - Input.get_action_strength(Actions.ACTION_GP_MOVE_UP)
	currentInput.normalized()

#
func UpdateVelocity(deltaTime):
	if currentInput != Vector2.ZERO:
		currentVelocity = currentVelocity.move_toward(currentInput * stat.moveSpeed, stat.moveAcceleration * deltaTime)
	else:
		currentVelocity = currentVelocity.move_toward(Vector2.ZERO, stat.moveFriction * deltaTime)

	currentVelocity = move_and_slide(currentVelocity)

#
func UpdateState():
	var nextState		= GetNextState()
	var nextDirection	= GetNextDirection()
	var newState		= nextState != currentState
	var newDirection	= nextDirection != currentDirection

	if newState || newDirection:
		ApplyNextState(nextState, nextDirection)

#
func _physics_process(deltaTime) :
	UpdateInput()
	UpdateVelocity(deltaTime)
	UpdateState()
