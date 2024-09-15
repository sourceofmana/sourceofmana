extends Actor
class_name BaseAgent

#
var agent : NavigationAgent2D			= null
var entityRadius : int					= 0

var behaviour : int						= AICommons.Behaviour.NONE
var aiState : AICommons.State			= AICommons.State.IDLE
var aiTimer : Timer						= null
var actionTimer : Timer					= null
var regenTimer : Timer					= null
var cooldownTimers : Dictionary			= {}
var attackers : Array					= []

var hasCurrentGoal : bool				= false
var isRelativeMode : bool				= false
var lastPositions : Array[float]		= []

var currentDirection : Vector2			= Vector2.ZERO
var currentOrientation : Vector2		= Vector2.ZERO
var currentSkillID : int				= -1
var currentVelocity : Vector2i			= Vector2i.ZERO
var currentInput : Vector2				= Vector2.ZERO
var forceUpdate : bool					= false

var spawnInfo : SpawnObject				= null
var skillSet : Array[SkillCell]			= []
var skillProba : Dictionary				= {}
var skillProbaSum : float				= 0.0
var skillSelected : SkillCell			= null

const inputApproximationUnit : int		= 12

#
func SwitchInputMode(clearCurrentInput : bool):
	hasCurrentGoal = false

	if clearCurrentInput:
		currentInput = Vector2.ZERO
		currentDirection = Vector2.ZERO

func UpdateInput():
	if isRelativeMode:
		if currentDirection != Vector2.ZERO:
			var pos : Vector2i = currentDirection.normalized() * ActorCommons.DisplacementVector + position
			if WorldNavigation.GetPathLengthSquared(self, pos) <= ActorCommons.MaxDisplacementSquareLength:
				WalkToward(pos)
				currentInput = currentDirection
		else:
			SwitchInputMode(true)

	if hasCurrentGoal:
		if agent && not agent.is_navigation_finished():
			var clampedDirection : Vector2 = Vector2(global_position.direction_to(agent.get_next_path_position()).normalized() * inputApproximationUnit)
			currentInput = Vector2(clampedDirection) / inputApproximationUnit

			lastPositions.push_back(agent.distance_to_target())
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
	if state == ActorCommons.State.WALK:
		nextVelocity = currentVelocity
		move_and_slide()

	if velocity != nextVelocity:
		var velocityDiff : Vector2 = (nextVelocity - velocity).abs()
		if (velocityDiff.x + velocityDiff.y) > 5 or velocity.is_zero_approx() or nextVelocity.is_zero_approx():
			velocity = nextVelocity
			forceUpdate = true

func SetCurrentState():
	if stat.health <= 0:
		SetState(ActorCommons.State.DEATH)
	elif currentSkillID != DB.UnknownHash:
		SetState(DB.SkillsDB[currentSkillID].state)
	elif currentVelocity == Vector2i.ZERO:
		SetState(ActorCommons.State.IDLE)
	else:
		SetState(ActorCommons.State.WALK)

func SetState(wantedState : ActorCommons.State) -> bool:
	var nextState : ActorCommons.State = ActorCommons.GetNextTransition(state, wantedState)
	forceUpdate = forceUpdate or nextState != state
	state = nextState
	return state == wantedState

func SetSkillCastID(skillID : int):
	forceUpdate = forceUpdate or currentSkillID in DB.SkillsDB
	currentSkillID = skillID
	if skillID == DB.UnknownHash:
		skillSelected = null

func AddSkill(skill : SkillCell, proba : float):
	if skill and not skillSet.has(skill):
		skillSet.append(skill)
	skillProba[skill] = proba
	skillProbaSum += proba

func AddItem(item : BaseCell, proba : float):
	if item and inventory:
		while proba > 0.0:
			if proba >= 1.0 or randf_range(0.0, 1.0) <= proba:
				inventory.PushItem(item, 1)
				proba -= 1.0
			else:
				break

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

	if DB.SkillsDB.has(currentSkillID):
		Skill.Stopped(self)

	hasCurrentGoal = true
	lastPositions.clear()
	if agent:
		agent.target_position = pos

func ResetNav():
	WalkToward(position)
	SwitchInputMode(true)

func UpdateChanged():
	forceUpdate = false
	if currentInput != Vector2.ZERO:
		currentOrientation = Vector2(currentVelocity).normalized()
	var functionName : String = "ForceUpdateEntity" if velocity == Vector2.ZERO else "UpdateEntity"
	Launcher.Network.Server.NotifyNeighbours(self, functionName, [velocity, position, currentOrientation, state, currentSkillID])

#
func SetData(data : EntityData):
	for skillID in data._skillSet:
		AddSkill(DB.SkillsDB[skillID], data._skillProba[skillID])

	for itemID in data._drops:
		AddItem(DB.ItemsDB[itemID], data._dropsProba[itemID])

	entityRadius = data._radius
	behaviour = data._behaviour

	# Navigation
	if !(behaviour & AICommons.Behaviour.IMMOBILE):
		if self is PlayerAgent:
			agent = FileSystem.LoadEntityComponent("navigations/PlayerAgent")
		else:
			agent = FileSystem.LoadEntityComponent("navigations/NPAgent")
		agent.set_radius(data._radius)
		agent.set_neighbor_distance(data._radius * 2)
		agent.velocity_computed.connect(self._velocity_computed)
		add_child.call_deferred(agent)

#
func Damage(_caller : BaseAgent):
	pass

func Interact(_caller : BaseAgent):
	pass

func GetNextShapeID() -> String:
	return stat.entityShape if stat.IsMorph() else stat.spiritShape

func GetNextPortShapeID() -> String:
	return stat.spiritShape if stat.IsSailing() else "Ship"

#
func AddAttacker(attacker : BaseAgent, damage : int = 0):
	if attacker:
		var currentTick : int = Time.get_ticks_msec()
		for entry in attackers:
			if entry.attacker == attacker:
				entry.damage += damage
				entry.time = currentTick
				return

		attackers.append({"attacker": attacker, "damage": damage, "time": currentTick})
		if attackers.size() > AICommons.maxAttackerCount:
			RemoveOldestAttacker()

func RemoveOldestAttacker():
	attackers.sort_custom(func(a, b): return a.time < b.time)
	attackers.erase(0)

func GetMostValuableAttacker() -> BaseAgent:
	var target : BaseAgent = null
	var maxDamage : int = -1
	for entry in attackers:
		if SkillCommons.IsInteractable(self, entry.attacker) and entry.damage > maxDamage:
			maxDamage = entry.damage
			target = entry.attacker
	return target

func GetNearbyMostValuableAttacker() -> BaseAgent:
	var target : BaseAgent = null
	var maxDamage : int = -1
	for entry in attackers:
		if entry.attacker and AICommons.IsReachable(self, entry.attacker) and entry.damage > maxDamage:
			maxDamage = entry.damage
			target = entry.attacker
	return target

func GetDamageRatio(attacker : BaseAgent) -> float:
	for entry in attackers:
		if entry.attacker == attacker:
			if entry.time > Time.get_ticks_msec() - ActorCommons.AttackTimestampLimit and stat.current.maxHealth > 0:
				return float(entry.damage) / float(stat.current.maxHealth) if entry.damage < stat.current.maxHealth else 1.0
	return 0.0

func Killed():
	SetSkillCastID(DB.UnknownHash)

#
func _physics_process(_delta):
	if agent:
		UpdateInput()

		if agent.get_avoidance_enabled():
			agent.set_velocity(currentVelocity)
		else:
			_velocity_computed(currentVelocity)
	else:
		if forceUpdate:
			UpdateChanged()

func _velocity_computed(safeVelocity : Vector2i):
	currentVelocity = safeVelocity
	SetCurrentState()
	SetVelocity()

	if forceUpdate:
		UpdateChanged()

func _ready():
	set_name.call_deferred(str(get_rid().get_id()))

	actionTimer = Timer.new()
	actionTimer.set_name("ActionTimer")
	actionTimer.set_one_shot(true)
	add_child.call_deferred(actionTimer)
