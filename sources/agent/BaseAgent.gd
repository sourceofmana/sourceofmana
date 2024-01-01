extends CharacterBody2D
class_name BaseAgent

#
var agent : NavigationAgent2D			= null
var agentName : String					= ""
var agentType : String					= ""

var aiTimer : Timer						= null
var castTimer : Timer					= null
var cooldownTimer : Timer				= null
var deathTimer : Timer					= null

var hasCurrentGoal : bool				= false
var isRelativeMode : bool				= false
var currentDirection : Vector2			= Vector2.ZERO
var currentOrientation : Vector2		= Vector2.ZERO

var currentState : EntityCommons.State	= EntityCommons.State.IDLE
var pastState : EntityCommons.State		= EntityCommons.State.IDLE

var isSitting : bool					= false
var isAttacking : bool					= false

var currentVelocity : Vector2i			= Vector2i.ZERO
var pastVelocity : Vector2				= Vector2.ZERO
var currentInput : Vector2				= Vector2.ZERO

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
	if currentState == EntityCommons.State.WALK:
		velocity = currentVelocity
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func SetCurrentState():
	if stat.health <= 0:
		SetState(EntityCommons.State.DEATH)
	elif isAttacking:
		SetState(EntityCommons.State.ATTACK)
	elif currentVelocity == Vector2i.ZERO:
		SetState(EntityCommons.State.IDLE)
	else:
		SetState(EntityCommons.State.WALK)

func SetState(nextState : EntityCommons.State) -> bool:
	currentState = EntityCommons.GetNextTransition(currentState, nextState)
	return currentState == nextState

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
	if isAttacking:
		Combat.TargetStopped(self)
	if isAttacking:
		return

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

func HasChanged() -> bool:
	if currentState != pastState:
		return true
	if velocity != pastVelocity:
		if velocity == Vector2.ZERO or pastVelocity == Vector2.ZERO:
			return true
		if (velocity - pastVelocity).abs() > Vector2(5, 5):
			return true
	return false

func UpdateChanged():
	pastVelocity = velocity
	pastState = currentState
	if currentInput != Vector2.ZERO:
		currentOrientation = Vector2(currentVelocity).normalized()

	var functionName : String = "ForceUpdateEntity" if velocity == Vector2.ZERO else "UpdateEntity"
	Launcher.Network.Server.NotifyInstancePlayers(get_parent(), self, functionName, [velocity, position, currentOrientation, currentState])


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
		cooldownTimer = Timer.new()
		cooldownTimer.set_name("CooldownTimer")
		cooldownTimer.set_one_shot(true)
		add_child.call_deferred(cooldownTimer)
		deathTimer = Timer.new()
		deathTimer.set_name("DeathTimer")
		deathTimer.set_one_shot(true)
		add_child.call_deferred(deathTimer)

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

func _internal_process():
	if agent and get_parent():
		UpdateInput()

		if agent.get_avoidance_enabled():
			agent.set_velocity(currentVelocity)
		else:
			_velocity_computed(currentVelocity)

	if HasChanged():
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
