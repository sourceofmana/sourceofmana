extends CharacterBody2D
class_name BaseEntity

@onready var animationState		= animationTree.get("parameters/playback")

var sprite : Sprite2D				= null
var animation : Node				= null
var animationTree : AnimationTree	= null
var agent : NavigationAgent2D		= null
var collision : CollisionShape2D	= null

var stat						= preload("res://sources/entity/components/Stat.gd").new()
var slot						= preload("res://sources/entity/components/Slot.gd").new()
var interactive					= load("res://sources/entity/components/Interactive.gd").new()
var inventory: EntityInventory	= load("res://sources/entity/components/inventory/Inventory.gd").new()

var entityName					= "PlayerName"
var gender						= Launcher.Entities.Trait.Gender.MALE

var damageReceived				= {}
var showName					= false

var hasGoal		                = false
var currentInput				= Vector2.ZERO
var currentVelocity				= Vector2.ZERO
var currentDirection			= Vector2(0, 1)

enum State { IDLE = 0, WALK, SIT, UNKNOWN = -1 }
var currentState				= State.IDLE
var currentStateTimer			= 0.0

var lastPositions : Array		= []

#
func GetNextDirection():
	if currentVelocity.length_squared() > 1:
		return currentVelocity.normalized()
	else:
		return currentDirection

func GetNextState():
	var newEnumState			= currentState
	var isWalking				= currentVelocity.length_squared() > 1
	match currentState:
		State.IDLE:
			if isWalking:
				newEnumState = State.WALK
		State.WALK:
			if isWalking == false:
				newEnumState = State.IDLE
		State.SIT:
			if isWalking:
				newEnumState = State.WALK

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
	hasGoal = false

	if clearCurrentInput:
		currentInput = Vector2.ZERO

	if Launcher.Debug:
		Launcher.Debug.ClearNavLine()

func UpdateInput():
	if hasGoal:
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

func WalkToward(pos : Vector2):
	hasGoal = true
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


func _setup_nav_agent():
	if agent:
		if agent.get_avoidance_enabled():
			var err = agent.velocity_computed.connect(self._velocity_computed)
			Launcher.Util.Assert(err == OK, "Could not connect the signal velocity_computed to the navigation agent")
		if Launcher.Debug:
			var err = agent.path_changed.connect(Launcher.Debug.UpdateNavLine)
			Launcher.Util.Assert(err == OK, "Could not connect the signal path_changed to Launcher.Debug.UpdateNavLine")


func _enable_warp():
	collision_layer |= 1 << 1
	collision_mask |= 1 << 1

func SetName(_entityID : String, _entityName : String):
	if _entityName.length() == 0:
		entityName = _entityID
		name =  _entityID
	else:
		entityName = _entityName
		name = _entityName


func applyEntityData(data: EntityData):
	stat.moveSpeed = data._walkSpeed
	if !data._ethnicity.is_empty() or !data._gender.is_empty():
		sprite = Launcher.FileSystem.LoadPreset("sprites/" + data._ethnicity + data._gender)
		if sprite != null && !data._customTexture.is_empty():
			sprite.texture = Launcher.FileSystem.LoadGfx(data._customTexture)
		add_child(sprite)
	if data._animation:
		animation = Launcher.FileSystem.LoadPreset("animations/" + data._animation)
		var canFetchAnimTree = animation != null && animation.has_node("AnimationTree")
		Launcher.Util.Assert(canFetchAnimTree, "No AnimationTree found")
		if canFetchAnimTree:
			animationTree = animation.get_node("AnimationTree")
		add_child(animation)
	if data._navigationAgent:
		agent = Launcher.FileSystem.LoadPreset("navigations/" + data._navigationAgent)
		add_child(agent)	
	if data._collision:
		collision = Launcher.FileSystem.LoadPreset("collisions/" + data._collision)
		add_child(collision)
