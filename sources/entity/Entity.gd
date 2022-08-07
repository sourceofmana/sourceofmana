extends KinematicBody2D

onready var animationTree		= $AnimationTree
onready var animationState		= animationTree.get("parameters/playback")

var stat						= preload("res://sources/entity/Stat.gd").new()
var slot						= preload("res://sources/entity/Slot.gd").new()
var inventory					= preload("res://sources/entity/Inventory.gd").new()

var entityName					= ""
var gender						= Launcher.Entities.Trait.Gender.MALE
var type						= Launcher.Entities.Trait.Type.HUMAN

var damageReceived				= {}
var showName					= false

var currentInput				= Vector2.ZERO
var currentVelocity				= Vector2.ZERO
var currentDirection			= Vector2.ZERO

var currentState				= Actions.State.IDLE
var currentStateTimer			= 0.0

var navPath : PoolVector2Array	= []

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

	if navPath:
		if not is_zero_approx(currentInput.length()) || navPath.size() <= 1:
			navPath = []
		else:
			if navPath.size() > 1 &&  (position - navPath[1]).length() < 5:
				navPath.remove(0)
				if Launcher.Debug:
					Launcher.Debug.UpdateNavLine()
			if navPath.size() > 1:
				currentInput = -(position - navPath[1])

func UpdateOrientation(deltaTime : float):
	if currentInput != Vector2.ZERO:
		var normalizedInput : Vector2 = currentInput.normalized()
		currentVelocity = currentVelocity.move_toward(normalizedInput * stat.moveSpeed, stat.moveAcceleration * deltaTime)
	else:
		currentVelocity = currentVelocity.move_toward(Vector2.ZERO, stat.moveFriction * deltaTime)

func UpdateVelocity():
	if currentState != Actions.State.SIT && currentVelocity != Vector2.ZERO:
		currentVelocity = move_and_slide(currentVelocity, Vector2.ZERO, false, 1, 0.1, false)

func UpdateState():
	var nextState		= GetNextState()
	var nextDirection	= GetNextDirection()
	var newState		= nextState != currentState
	var newDirection	= nextDirection != currentDirection

	if newState || newDirection:
		ApplyNextState(nextState, nextDirection)

#
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			get_tree().set_input_as_handled()

			var playerPosOnWorld : Vector2 = Launcher.Entities.activePlayer.get_global_position()
			var mousePosOnWorld : Vector2 = Launcher.Camera.mainCamera.get_global_mouse_position()
			var navPolygon : Navigation2D = Launcher.Map.activeMap.get_node('Navigation2D')

			navPath = navPolygon.get_simple_path(playerPosOnWorld, mousePosOnWorld)

			if Launcher.Debug:
				Launcher.Debug.UpdateNavLine()

func _physics_process(deltaTime : float):
	UpdateInput()
	UpdateOrientation(deltaTime)
	UpdateVelocity()
	UpdateState()

func _ready():
	set_process_input(true)
	set_process_unhandled_input(true)
