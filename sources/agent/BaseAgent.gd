extends CharacterBody2D
class_name BaseAgent

#
var agent : NavigationAgent2D			= null
var agentName : String					= ""
var agentType : String					= ""

var aiTimer : Timer						= null
var castTimer : Timer					= null
var cooldownTimers : Dictionary			= {}

var hasCurrentGoal : bool				= false
var isRelativeMode : bool				= false

var currentDirection : Vector2			= Vector2.ZERO
var currentOrientation : Vector2		= Vector2.ZERO
var currentState : EntityCommons.State	= EntityCommons.State.IDLE
var currentSkillCastID : int			= -1
var currentVelocity : Vector2i			= Vector2i.ZERO
var currentInput : Vector2				= Vector2.ZERO
var forceUpdate : bool					= false

var lastPositions : Array[Vector2]		= []
var navigationLine : PackedVector2Array	= []

var spawnInfo : SpawnObject				= null
var stat : EntityStats					= EntityStats.new()
var inventory : EntityInventory			= EntityInventory.new()

const inputApproximationUnit : int		= 12

#
func SwitchInputMode(clearCurrentInput : bool):
	hasCurrentGoal = false

	if clearCurrentInput:
		currentInput = Vector2.ZERO
		currentDirection = Vector2.ZERO

	navigationLine = []

func UpdateInput():
	if isRelativeMode:
		if currentDirection != Vector2.ZERO:
			var pos : Vector2i = currentDirection.normalized() * Vector2(32,32) + position
			if WorldNavigation.GetPathLength(self, pos) <= 64:
				WalkToward(pos)
				currentInput = currentDirection
		else:
			SwitchInputMode(true)

	if hasCurrentGoal:
		if agent && not agent.is_navigation_finished():
			var clampedDirection : Vector2 = Vector2(global_position.direction_to(agent.get_next_path_position()).normalized() * inputApproximationUnit)
			currentInput = Vector2(clampedDirection) / inputApproximationUnit

			lastPositions.push_back(position)
			if lastPositions.size() > 5:
				lastPositions.pop_front()
		else:
			SwitchInputMode(true)

	if currentInput != Vector2.ZERO:
		currentVelocity = currentInput * stat.current.walkSpeed
	else:
		currentVelocity = Vector2i.ZERO

func SetVelocity():
	var nextVelocity : Vector2 = Vector2.ZERO
	if currentState == EntityCommons.State.WALK:
		nextVelocity = currentVelocity
		move_and_slide()

	var velocityDiff : Vector2 = (nextVelocity - velocity).abs()
	if (velocityDiff.x + velocityDiff.y) > 5 or (velocity != nextVelocity and (velocity.is_zero_approx() or nextVelocity.is_zero_approx())):
		velocity = nextVelocity
		forceUpdate = true

func SetCurrentState():
	if stat.health <= 0:
		SetState(EntityCommons.State.DEATH)
	elif currentSkillCastID >= 0:
		SetState(Launcher.DB.SkillsDB[str(currentSkillCastID)]._state)
	elif currentVelocity == Vector2i.ZERO:
		SetState(EntityCommons.State.IDLE)
	else:
		SetState(EntityCommons.State.WALK)

func SetState(wantedState : EntityCommons.State) -> bool:
	var nextState : EntityCommons.State = EntityCommons.GetNextTransition(currentState, wantedState)
	forceUpdate = forceUpdate or nextState != currentState
	currentState = nextState
	return currentState == wantedState

func SetSkillCastID(skillID : int):
	forceUpdate = forceUpdate or skillID != currentSkillCastID
	currentSkillCastID = skillID

func SetRelativeMode(enable : bool, givenDirection : Vector2):
	if isRelativeMode != enable:
		isRelativeMode = enable
	if givenDirection == Vector2.ZERO:
		ResetNav()
		isRelativeMode = false
	currentDirection = givenDirection

func WalkToward(pos : Vector2):
	if pos == position:
		return

	if currentSkillCastID >= 0:
		Skill.Stopped(self)

	hasCurrentGoal = true
	lastPositions.clear()
	if agent:
		agent.target_position = pos
		navigationLine.clear()
		navigationLine = agent.get_current_navigation_path()

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

func UpdateChanged():
	forceUpdate = false
	if currentInput != Vector2.ZERO:
		currentOrientation = Vector2(currentVelocity).normalized()
	var functionName : String = "ForceUpdateEntity" if velocity == Vector2.ZERO else "UpdateEntity"
	Launcher.Network.Server.NotifyInstancePlayers(get_parent(), self, functionName, [velocity, position, currentOrientation, currentState, currentSkillCastID])

#
func SetKind(entityType : String, entityID : String, entityName : String):
	agentType	= entityType
	agentName	= entityID if entityName.length() == 0 else entityName
	set_name(agentName)

	if self is MonsterAgent or self is NpcAgent:
		aiTimer = Timer.new()
		aiTimer.set_name("AiTimer")
		add_child.call_deferred(aiTimer)
	if self is MonsterAgent or self is PlayerAgent:
		castTimer = Timer.new()
		castTimer.set_name("CastTimer")
		castTimer.set_one_shot(true)
		add_child.call_deferred(castTimer)

func SetData(data : EntityData):
	# Stat
	stat.Init(data)

	# Navigation
	if data._navigationAgent.length() > 0:
		agent = FileSystem.LoadEntityComponent("navigations/" + data._navigationAgent)
		add_child.call_deferred(agent)

#
func Damage(_caller : BaseAgent):
	pass

func Interact(_caller : BaseAgent):
	pass

func GetCurrentShapeID() -> String:
	return stat.spiritShape if stat.morphed else stat.entityShape

func GetNextShapeID() -> String:
	return stat.spiritShape if not stat.morphed else stat.entityShape

#
func _specific_process():
	pass

func _physics_process(_delta):
	if agent:
		UpdateInput()

		if agent.get_avoidance_enabled():
			agent.set_velocity(currentVelocity)
		else:
			_velocity_computed(currentVelocity)

	if forceUpdate:
		UpdateChanged()

	_specific_process()

func _velocity_computed(safeVelocity : Vector2):
	currentVelocity = safeVelocity

	SetCurrentState()
	SetVelocity()

func _path_changed():
	if agent:
		navigationLine = agent.get_current_navigation_path()

func _target_reached():
	navigationLine = []

func _setup_nav_agent():
	if agent && agent.get_avoidance_enabled():
		var err : int = agent.velocity_computed.connect(self._velocity_computed)
		Util.Assert(err == OK, "Could not connect the signal velocity_computed to the navigation agent")
		err = agent.path_changed.connect(self._path_changed)
		Util.Assert(err == OK, "Could not connect the signal path_changed to the local function _path_changed")
		err = agent.target_reached.connect(self._target_reached)
		Util.Assert(err == OK, "Could not connect the signal path_changed to the local function _target_reached")

func _ready():
	_setup_nav_agent()
	set_name.call_deferred(str(get_rid().get_id()))
