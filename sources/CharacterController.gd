extends KinematicBody2D

enum Actions { IDLE = 0, WALK, SIT, UNKNOWN = -1 }

const ACTION_GP_MOVE_RIGHT		= "gp_move_right"
const ACTION_GP_MOVE_LEFT		= "gp_move_left"
const ACTION_GP_MOVE_UP			= "gp_move_up"
const ACTION_GP_MOVE_DOWN		= "gp_move_down"
const ACTION_GP_SIT				= "gp_sit"

const ACCELERATION				= 600
const FRICTION					= 800
const MAX_SPEED					= 125

onready var animationTree		= $AnimationTree
onready var animationState		= animationTree.get("parameters/playback")

var currentInput				= Vector2.ZERO
var currentVelocity				= Vector2.ZERO
var currentDirection			= Vector2.ZERO
var currentState				= Actions.IDLE


#
func GetNextDirection():
	if currentVelocity.length_squared() > 1:
		return currentVelocity.normalized()
	else:
		return currentDirection

func GetNextState():
	var newEnumState			= currentState
	var isWalking				= currentVelocity.length_squared() > 1
	var actionSitPressed		= Input.is_action_pressed(ACTION_GP_SIT)
	var actionSitJustPressed	= Input.is_action_just_pressed(ACTION_GP_SIT)

	match currentState:
		Actions.IDLE:
			if isWalking:
				newEnumState = Actions.WALK
			elif actionSitJustPressed:
				newEnumState = Actions.SIT
		Actions.WALK:
			if isWalking == false:
				newEnumState = Actions.IDLE
		Actions.SIT:
			if actionSitPressed == false && isWalking:
				newEnumState = Actions.WALK
			elif actionSitJustPressed:
				newEnumState = Actions.IDLE

	return newEnumState

func ApplyNextState(nextState, nextDirection):
	currentState		= nextState
	currentDirection	= nextDirection

	animationTree.set("parameters/Idle/blend_position", currentDirection)
	animationTree.set("parameters/Sit/blend_position", currentDirection)
	animationTree.set("parameters/Walk/blend_position", currentDirection)

	match currentState:
		Actions.IDLE:
			animationState.travel("Idle")
		Actions.WALK:
			animationState.travel("Walk")
		Actions.SIT:
			animationState.travel("Sit")


#
func UpdateInput():
	currentInput.x	= Input.get_action_strength(ACTION_GP_MOVE_RIGHT) - Input.get_action_strength(ACTION_GP_MOVE_LEFT)
	currentInput.y	= Input.get_action_strength(ACTION_GP_MOVE_DOWN) - Input.get_action_strength(ACTION_GP_MOVE_UP)
	currentInput.normalized()

#
func UpdateVelocity(deltaTime):
	if currentInput != Vector2.ZERO:
		currentVelocity = currentVelocity.move_toward(currentInput * MAX_SPEED, ACCELERATION * deltaTime)
	else:
		currentVelocity = currentVelocity.move_toward(Vector2.ZERO, FRICTION * deltaTime)

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
