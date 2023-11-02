extends CharacterBody2D
class_name BaseAgent

#
var agent : NavigationAgent2D			= null
var agentName : String					= ""
var agentType : String					= ""
var agentID : String					= ""

var aiTimer : Timer						= null
var castTimer : Timer					= null
var cooldownTimer : Timer				= null
var deathTimer : Timer					= null

var hasCurrentGoal : bool				= false
var isRelativeMode : bool				= false
var currentDirection : Vector2			= Vector2.ZERO

var currentState : EntityCommons.State	= EntityCommons.State.IDLE
var pastState : EntityCommons.State		= EntityCommons.State.IDLE

var isSitting : bool					= false
var isAttacking : bool					= false
var target : BaseAgent					= null

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

	navigationLine = []

func UpdateInput():
	if isRelativeMode:
		if currentDirection != Vector2.ZERO:
			var pos : Vector2i = currentDirection.normalized() * Vector2(32,32) + position
			if WorldNavigation.GetPathLength(self, pos) <= 64:
				WalkToward(pos)
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

func UpdateOrientation():
	if currentInput != Vector2.ZERO:
		currentVelocity = currentInput * stat.current.walkSpeed
	else:
		currentVelocity = Vector2.ZERO

func SetVelocity():
	if currentState == EntityCommons.State.WALK:
		velocity = currentVelocity
		move_and_slide()
	else:
		velocity = Vector2.ZERO

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
	if pos != position and (target or isAttacking):
		Combat.Stop(self)

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
	return velocity != pastVelocity || currentState != pastState

func UpdateChanged():
	pastVelocity = velocity
	pastState = currentState

	var updateFuncName : String = "ForceUpdateEntity" if velocity == Vector2.ZERO else "UpdateEntity"
	Launcher.Network.Server.NotifyInstancePlayers(get_parent(), self, updateFuncName, [velocity, position, currentState])

#
func SetKind(entityType : String, entityID : String, entityName : String):
	agentType	= entityType
	agentID		= entityID

	agentName	= agentID if entityName.length() == 0 else entityName
	set_name(agentName)

	if self is MonsterAgent or self is NpcAgent:
		aiTimer = Timer.new()
		aiTimer.set_name("AiTimer")
		add_child(aiTimer)
	if self is MonsterAgent or self is PlayerAgent:
		castTimer = Timer.new()
		castTimer.set_name("CastTimer")
		castTimer.set_one_shot(true)
		add_child(castTimer)
		cooldownTimer = Timer.new()
		cooldownTimer.set_name("CooldownTimer")
		cooldownTimer.set_one_shot(true)
		add_child(cooldownTimer)
		deathTimer = Timer.new()
		deathTimer.set_name("DeathTimer")
		deathTimer.set_one_shot(true)
		add_child(deathTimer)

func SetData(data : Object):
	# Stat
	stat.Init(data)

	# Navigation
	if data._navigationAgent:
		agent = FileSystem.LoadEntityComponent("navigations/" + data._navigationAgent)
		add_child(agent)

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
		if agentName != "Reid":
			pass
		UpdateInput()
		UpdateOrientation()

		if agent.get_avoidance_enabled():
			agent.set_velocity(currentVelocity)
		else:
			_velocity_computed(currentVelocity)

		if HasChanged():
			UpdateChanged()

		_specific_process()

func _velocity_computed(safeVelocity : Vector2):
	currentVelocity = safeVelocity

	if stat.health <= 0:
		SetState(EntityCommons.State.DEATH)
#	elif isSitting:
#		SetState(EntityCommons.State.SIT)
	elif isAttacking:
		SetState(EntityCommons.State.ATTACK)
	elif currentVelocity == Vector2i.ZERO:
		SetState(EntityCommons.State.IDLE)
	else:
		SetState(EntityCommons.State.WALK)

	SetVelocity()

func _path_changed():
	if agent:
		navigationLine = agent.get_current_navigation_path()

func _target_reached():
	navigationLine = []

func _setup_nav_agent():
	if agent && agent.get_avoidance_enabled():
		var err = agent.velocity_computed.connect(self._velocity_computed)
		Util.Assert(err == OK, "Could not connect the signal velocity_computed to the navigation agent")
		err = agent.path_changed.connect(self._path_changed)
		Util.Assert(err == OK, "Could not connect the signal path_changed to the local function _path_changed")
		err = agent.target_reached.connect(self._target_reached)
		Util.Assert(err == OK, "Could not connect the signal path_changed to the local function _target_reached")

func _ready():
	_setup_nav_agent()
	set_name.call_deferred(str(get_rid().get_id()))
