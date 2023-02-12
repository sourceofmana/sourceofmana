extends CharacterBody2D
class_name BaseAgent

#
enum State { IDLE = 0, WALK, SIT, UNKNOWN = -1 }

#
var agent : NavigationAgent2D			= null
var agentName							= "PlayerName"
var aiTimer : AiTimer					= null
var stat : EntityStat					= null

var hasCurrentGoal						= false
var currentInput						= Vector2.ZERO
var currentVelocity						= Vector2.ZERO
var currentDirection					= Vector2(0, 1)
var currentState						= State.IDLE

var lastPositions : Array[Vector2]		= []
var navigationLine : PackedVector2Array	= []

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

func SwitchInputMode(clearCurrentInput : bool):
	hasCurrentGoal = false

	if clearCurrentInput:
		currentInput = Vector2.ZERO

	navigationLine = []

func UpdateInput():
	if hasCurrentGoal:
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
	hasCurrentGoal = true
	lastPositions.clear()
	if agent:
		agent.set_target_location(pos)
		navigationLine.clear()
		navigationLine += agent.get_current_navigation_path()

func ResetNav():
	WalkToward(position)
	navigationLine = []

func IsStuck() -> bool:
	var isStuck : bool = false
	if lastPositions.size() >= 5:
		var sum : Vector2 = Vector2.ZERO
		for pos in lastPositions:
			sum += pos - position
		isStuck = sum.abs() < Vector2(1, 1)
	return isStuck

#
func SetKind(entityType : String, entityID : String, entityName : String):
	if entityName.length() == 0:
		agentName = entityID
		name =  entityID
	else:
		agentName = entityName
		name = entityName

	if entityType == "Monster" or entityType == "Npc":
		aiTimer = AiTimer.new()
		add_child(aiTimer)

func SetData(data : Object):
	# Stat
	stat = EntityStat.new()
	stat.moveSpeed	= data._walkSpeed

	# Navigation
	if data._navigationAgent:
		agent = Launcher.FileSystem.LoadPreset("navigations/" + data._navigationAgent)
		add_child(agent)

#
func _physics_process(deltaTime : float):
	if agent:
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

func _path_changed():
	if agent:
		navigationLine = agent.get_current_navigation_path()

func _target_reached():
	navigationLine = []

func _setup_nav_agent():
	if agent && agent.get_avoidance_enabled():
		var err = agent.velocity_computed.connect(self._velocity_computed)
		Launcher.Util.Assert(err == OK, "Could not connect the signal velocity_computed to the navigation agent")
		err = agent.path_changed.connect(self._path_changed)
		Launcher.Util.Assert(err == OK, "Could not connect the signal path_changed to the local function _path_changed")
		err = agent.target_reached.connect(self._target_reached)
		Launcher.Util.Assert(err == OK, "Could not connect the signal path_changed to the local function _target_reached")

func _ready():
	_setup_nav_agent()
	set_name(str(get_rid().get_id()))
