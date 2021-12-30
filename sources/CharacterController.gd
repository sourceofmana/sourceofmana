extends KinematicBody2D

enum Actions { IDLE, WALK, SIT, UNKNOWN = -1 }

const ACCELERATION = 600
const FRICTION = 800
const MAX_SPEED = 125

var velocity = Vector2.ZERO
var enumState = Actions.IDLE

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

#
func HandleInputVector() :
	var input_vector = Vector2.ZERO

	input_vector.x = Input.get_action_strength( "gp_move_right" ) - Input.get_action_strength("gp_move_left" )
	input_vector.y = Input.get_action_strength( "gp_move_down" ) - Input.get_action_strength("gp_move_up" )
	input_vector.normalized()

	return input_vector

#
func HandleAnimationTree( delta ) :
	var input_vector = HandleInputVector()
	UpdateVelocity( input_vector, delta )

	var isWalking	= velocity.length_squared() > 1
	var isSitting	= Input.is_action_just_pressed( "gp_sit" )

	match enumState :
		Actions.IDLE :
			if isWalking :
				animationTree.set( "parameters/Idle/blend_position", velocity )
				animationTree.set( "parameters/Walk/blend_position", velocity )
				animationState.travel( "Walk" )
				enumState = Actions.WALK
			elif isSitting :
				animationState.travel( "Sit" )
				enumState = Actions.SIT
		Actions.WALK :
			if isWalking == false :
				animationState.travel( "Idle" )
				enumState = Actions.IDLE
		Actions.SIT :
			if isWalking :
				animationTree.set( "parameters/Sit/blend_position", velocity )
				animationTree.set( "parameters/Walk/blend_position", velocity )
				animationState.travel( "Walk" )
				enumState = Actions.WALK
			elif isSitting :
				animationState.travel( "Idle" )
				enumState = Actions.IDLE

#
func UpdateVelocity( input, delta ) :
	if input != Vector2.ZERO :
		velocity = velocity.move_toward( input * MAX_SPEED, ACCELERATION * delta )
	else :
		velocity = velocity.move_toward( Vector2.ZERO, FRICTION * delta )

	velocity = move_and_slide( velocity )

#
func _physics_process( delta ) :
	HandleAnimationTree( delta )
