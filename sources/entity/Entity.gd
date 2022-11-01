extends CharacterBody2D
class_name Entity

@onready var animationState		= animationTree.get("parameters/playback")

var sprite : Sprite2D				= null
var animation : Node				= null
var animationTree : AnimationTree	= null
var agent : NavigationAgent2D		= null
var camera : Camera2D				= null
var collision : CollisionShape2D	= null

var stat						= preload("res://sources/entity/Stat.gd").new()
var slot						= preload("res://sources/entity/Slot.gd").new()
var interactive					= load("res://sources/entity/interactive/Interactive.gd").new()
var inventory: EntityInventory	= load("res://sources/entity/Inventory.gd").new()

var entityName					= "PlayerName"
var gender						= Launcher.Entities.Trait.Gender.MALE
var type						= Launcher.Entities.Trait.Type.HUMAN

var damageReceived				= {}
var showName					= false

var isCapturingMouseInput		= false
var currentInput				= Vector2.ZERO
var currentVelocity				= Vector2.ZERO
var currentDirection			= Vector2(0, 1)

enum State { IDLE = 0, WALK, SIT, UNKNOWN = -1 }
var currentState				= State.IDLE
var currentStateTimer			= 0.0

var isPlayableController		= false
var lastPositions : Array		= []
var AITimer : Timer				= null


#
func GetNextDirection():
	if currentVelocity.length_squared() > 1:
		return currentVelocity.normalized()
	else:
		return currentDirection

func GetNextState():
	var newEnumState			= currentState
	var isWalking				= currentVelocity.length_squared() > 1
	var actionSitPressed		= Launcher.Action.IsActionPressed("gp_sit") if isPlayableController else false
	var actionSitJustPressed	= Launcher.Action.IsActionJustPressed("gp_sit") if isPlayableController else false

	match currentState:
		State.IDLE:
			if isWalking:
				newEnumState = State.WALK
			elif actionSitJustPressed:
				newEnumState = State.SIT
		State.WALK:
			if isWalking == false:
				newEnumState = State.IDLE
		State.SIT:
			if actionSitPressed == false && isWalking:
				newEnumState = State.WALK
			elif actionSitJustPressed:
				newEnumState = State.IDLE

	return newEnumState

func ApplyNextState(nextState, nextDirection):
	currentState		= nextState
	currentDirection	= nextDirection

	animationTree.set("parameters/Idle/blend_position", currentDirection)
	animationTree.set("parameters/Sit/blend_position", currentDirection)
	animationTree.set("parameters/Walk/blend_position", currentDirection)

	match currentState:
		State.IDLE:
			animationState.travel("Idle")
		State.WALK:
			animationState.travel("Walk")
		State.SIT:
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
			lastPositions.push_back(position)
			if lastPositions.size() > 5:
				lastPositions.pop_front()
		else:
			SwitchInputMode(true)

func UpdateOrientation(deltaTime : float):
	if currentInput != Vector2.ZERO:
		var normalizedInput : Vector2 = currentInput.normalized()
		currentVelocity = currentVelocity.move_toward(normalizedInput * stat.moveSpeed, stat.moveAcceleration * deltaTime)
	else:
		currentVelocity = currentVelocity.move_toward(Vector2.ZERO, stat.moveFriction * deltaTime)

func UpdateVelocity():
	if currentState != State.SIT && currentVelocity != Vector2.ZERO:
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
func WalkToward(pos : Vector2):
	isCapturingMouseInput = true
	lastPositions.clear()
	if agent:
		agent.set_target_location(pos)

func ResetNav():
	WalkToward(position)

func IsStuck() -> bool:
	var isStuck : bool = false
	if lastPositions.size() >= 5:
		var sum : Vector2 = Vector2.ZERO
		for pos in lastPositions:
			sum += pos - position
		isStuck = sum.abs() < Vector2(1, 1)
	return isStuck

#
func AddAITimer(delay : float, callable: Callable, map : Object):
	AITimer.stop()
	AITimer.start(delay)
	AITimer.autostart = true
	if not AITimer.timeout.is_connected(callable):
		AITimer.timeout.connect(callable.bind(self, map))

#
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			WalkToward(Launcher.Camera.mainCamera.get_global_mouse_position())

	currentInput = Launcher.Action.GetMove()
	if currentInput.length() > 0:
		SwitchInputMode(false)

func _physics_process(deltaTime : float):
	UpdateInput()
	UpdateOrientation(deltaTime)
	if agent.get_avoidance_enabled():
		agent.set_velocity(currentVelocity)
	else:
		_velocity_computed(currentVelocity)
	if interactive:
		interactive.Update(isPlayableController)

func _velocity_computed(safeVelocity : Vector2):
	currentVelocity = safeVelocity
	UpdateVelocity()
	UpdateState()

func _ready():
	set_process_input(isPlayableController)
	set_process_unhandled_input(isPlayableController)

	if agent:
		if agent.get_avoidance_enabled():
			var err = agent.velocity_computed.connect(self._velocity_computed)
			Launcher.Util.Assert(err == OK, "Could not connect the signal velocity_computed to the navigation agent")
		if Launcher.Debug:
			var err = agent.path_changed.connect(Launcher.Debug.UpdateNavLine)
			Launcher.Util.Assert(err == OK, "Could not connect the signal path_changed to Launcher.Debug.UpdateNavLine")

	if interactive:
		interactive.Setup(self, isPlayableController)

	if AITimer == null:
		AITimer = Timer.new()
		AITimer.set_name("Timer")
		add_child(AITimer)
