extends CharacterBody2D
class_name BaseAgent

#
var agent : NavigationAgent2D			= null
var agentName : String					= ""
var agentType : String					= ""
var agentID : String					= ""

var aiTimer : AiTimer					= null
var hasCurrentGoal : bool				= false

var currentState : EntityCommons.State	= EntityCommons.State.IDLE
var currentInput : Vector2				= Vector2.ZERO
var currentVelocity : Vector2			= Vector2.ZERO
var isSitting : bool					= false

var pastVelocity : Vector2				= Vector2.ZERO
var pastPosition : Vector2				= Vector2.ZERO
var wasSitting : bool					= false

var lastPositions : Array[Vector2]		= []
var navigationLine : PackedVector2Array	= []

var spawnInfo : SpawnObject				= null
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

func UpdateOrientation():
	if currentInput != Vector2.ZERO:
		var normalizedInput : Vector2 = currentInput.normalized()
		currentVelocity = normalizedInput * stat.moveSpeed
	else:
		currentVelocity = Vector2.ZERO

func SetVelocity():
	velocity = currentVelocity
	if velocity != Vector2.ZERO:
		isSitting = false
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
	SwitchInputMode(true)

func IsStuck() -> bool:
	var isStuck : bool = false
	if lastPositions.size() >= 5:
		var sum : Vector2 = Vector2.ZERO
		for pos in lastPositions:
			sum += pos - position
		isStuck = sum.abs() < Vector2(1, 1)
	return isStuck

func HasChanged() -> bool:
	return position != pastPosition || velocity != pastVelocity || isSitting != wasSitting

func UpdateChanged():
	pastPosition = position
	pastVelocity = velocity
	wasSitting = isSitting

	if get_parent():
		var updateFuncName : String = "ForceUpdateEntity" if velocity == Vector2.ZERO else "UpdateEntity"
		Launcher.Network.Server.NotifyInstancePlayers(get_parent(), self, updateFuncName, [velocity, position, isSitting])

#
func SetKind(entityType : String, entityID : String, entityName : String):
	agentType	= entityType
	agentID		= entityID

	if entityName.length() == 0:
		agentName	= agentID
	else:
		agentName	= entityName
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
func Trigger(_caller : BaseAgent):
	pass

#
func _internal_process():
	if agent and get_parent():
		UpdateInput()
		UpdateOrientation()

		if agent.get_avoidance_enabled():
			agent.set_velocity(currentVelocity)
		else:
			_velocity_computed(currentVelocity)

func _velocity_computed(safeVelocity : Vector2):
	currentVelocity = safeVelocity
	currentState = EntityCommons.GetNextState(currentState, currentVelocity, isSitting)
	SetVelocity()

	if HasChanged():
		UpdateChanged()

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
