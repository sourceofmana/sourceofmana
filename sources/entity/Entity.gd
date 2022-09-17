extends CharacterBody2D

@onready var animationState		= animationTree.get("parameters/playback")

var sprite : Sprite2D				= null
var animation : Node				= null
var animationTree : AnimationTree	= null
var agent : NavigationAgent2D		= null
var camera : Camera2D				= null
var collision : CollisionShape2D	= null

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

func SwitchInputMode(clearCurrentInput : bool):
	isCapturingMouseInput = false

	if clearCurrentInput:
		currentInput = Vector2.ZERO

	if Launcher.Debug:
		Launcher.Debug.ClearNavLine()

#
func UpdateInput():
	if isCapturingMouseInput:
		if agent && not agent.is_navigation_finished():
			var newDirection : Vector2 = global_position.direction_to(agent.get_next_location())
			if newDirection != Vector2.ZERO:
				currentInput = newDirection
		else:
			SwitchInputMode(true)

func UpdateOrientation(deltaTime : float):
	if currentInput != Vector2.ZERO:
		var normalizedInput : Vector2 = currentInput.normalized()
		currentVelocity = currentVelocity.move_toward(normalizedInput * stat.moveSpeed, stat.moveAcceleration * deltaTime)
	else:
		currentVelocity = currentVelocity.move_toward(Vector2.ZERO, stat.moveFriction * deltaTime)

func UpdateVelocity():
	if currentState != Actions.State.SIT && currentVelocity != Vector2.ZERO:
		velocity = currentVelocity
		move_and_slide()


func UpdateState():
	var nextState		= GetNextState()
	var nextDirection	= GetNextDirection()
	var newState		= nextState != currentState
	var newDirection	= nextDirection != currentDirection

	if newState || newDirection:
		ApplyNextState(nextState, nextDirection)

#
func Warped(map : Node2D):
	var nav2d : Node2D = null

	if map && map.has_node("Navigation"):
		nav2d = map.get_node("Navigation")

	Launcher.Util.Assert(nav2d != null, "Navigation layer not found on current map")

#
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			isCapturingMouseInput = true
			#Todo: Use signal to know when the agent is instancied and to launch Map's warp func
			Warped(Launcher.Map.activeMap)
			if agent:
				agent.set_target_location(Launcher.Camera.mainCamera.get_global_mouse_position())

	currentInput.x	= Input.get_action_strength(Actions.ACTION_GP_MOVE_RIGHT) - Input.get_action_strength(Actions.ACTION_GP_MOVE_LEFT)
	currentInput.y	= Input.get_action_strength(Actions.ACTION_GP_MOVE_DOWN) - Input.get_action_strength(Actions.ACTION_GP_MOVE_UP)
	currentInput.normalized()
	if currentInput.length() > 0:
		SwitchInputMode(false)

func _physics_process(deltaTime : float):
	UpdateInput()
	UpdateOrientation(deltaTime)
	if agent.get_avoidance_enabled():
		agent.set_velocity(currentVelocity)
	else:
		_velocity_computed(currentVelocity)

func _velocity_computed(safeVelocity : Vector2):
	currentVelocity = safeVelocity
	UpdateVelocity()
	UpdateState()

func _ready():
	set_process_input(true)
	set_process_unhandled_input(true)

	#Todo: Use signal to know when the agent is instancied and to launch Map's warp func
	Warped(Launcher.Map.activeMap)

	if agent:
		if agent.get_avoidance_enabled():
			var err = agent.velocity_computed.connect(self._velocity_computed)
			assert(err == OK, "Could not connect the signal velocity_computed to the navigation agent")
		if Launcher.Debug:
			var err = agent.path_changed.connect(Launcher.Debug.UpdateNavLine)
			assert(err == OK, "Could not connect the signal path_changed to Launcher.Debug.UpdateNavLine")
