extends KinematicBody2D

onready var animationTree		= $AnimationTree
onready var animationState		= animationTree.get("parameters/playback")

var agent: NavigationAgent2D	= null

var stat						= preload("res://sources/entity/Stat.gd").new()
var slot						= preload("res://sources/entity/Slot.gd").new()
var inventory					= preload("res://sources/entity/Inventory.gd").new()

var entityName					= ""
var gender						= Launcher.Entities.Trait.Gender.MALE
var type						= Launcher.Entities.Trait.Type.HUMAN

var damageReceived				= {}
var showName					= false

var isCapturingMouseInput		= false
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

	if isCapturingMouseInput:
		var mousePosOnWorld : Vector2 = Launcher.Camera.mainCamera.get_global_mouse_position()
		Warped(Launcher.Map.activeMap)
		if agent:
			agent.set_target_location(mousePosOnWorld)

	if agent and not agent.is_navigation_finished():
		currentInput = global_position.direction_to(agent.get_next_location())

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
func Warped(map : Node2D):
	var nav2d : Navigation2D = null

	if map && map.has_node("Navigation2D"):
		nav2d = map.get_node("Navigation2D")
	if not agent && has_node("NavAgent"):
		agent = get_node("NavAgent")

	if agent:
		assert(nav2d != null, "Navigation layer not found on current map")
		agent.set_navigation(nav2d)

#
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			isCapturingMouseInput = event.pressed
			get_tree().set_input_as_handled()

func _physics_process(deltaTime : float):
	UpdateInput()
	UpdateOrientation(deltaTime)
	UpdateVelocity()
	UpdateState()

func _ready():
	set_process_input(true)
	set_process_unhandled_input(true)

	if Launcher.Debug && agent:
		var err = agent.connect("path_changed", Launcher.Debug, "UpdateNavLine")
		assert(err == OK, "Could not connect the signal path_changed to Launcher.Debug.UpdateNavLine")
