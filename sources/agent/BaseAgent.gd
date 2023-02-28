extends CharacterBody2D
class_name BaseAgent

#
var agent : NavigationAgent2D			= null
var agentName : String					= ""
var agentType : String					= ""
var agentID : String					= ""
var aiTimer : AiTimer					= null

var hasCurrentGoal : bool				= false
var currentInput : Vector2				= Vector2.ZERO
var currentVelocity : Vector2			= Vector2.ZERO

var lastPositions : Array[Vector2]		= []
var navigationLine : PackedVector2Array	= []

var stat : EntityStats					= EntityStats.new()

#
func SwitchInputMode(clearCurrentInput : bool):
	hasCurrentGoal = false

	if clearCurrentInput:
		currentInput = Vector2.ZERO

	navigationLine = []

func UpdateInput():
	if hasCurrentGoal:
		if agent && not agent.is_navigation_finished():
			var newDirection : Vector2 = global_position.direction_to(agent.get_next_path_position())
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

func SetVelocity():
	if currentVelocity != Vector2.ZERO:
		velocity = currentVelocity
		move_and_slide()

func WalkToward(pos : Vector2):
	hasCurrentGoal = true
	lastPositions.clear()
	if agent:
		agent.target_position = pos
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
	agentName	= entityName
	agentType	= entityType
	agentID		= entityID

	if agentName.length() == 0:
		set_name(agentID)
	else:
		set_name(agentName)

	if agentType == "Monster" or agentType == "Npc":
		aiTimer = AiTimer.new()
		add_child(aiTimer)

func SetData(data : Object):
	# Stat
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
	SetVelocity()

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
	name = str(get_rid().get_id())
