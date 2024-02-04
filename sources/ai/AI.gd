extends Object
class_name AI

#
enum State
{
	IDLE = 0,
	WALK,
	ATTACK,
	HALT,
}

#
const transitions : Array[Array] = [
#	IDLE			WALK			ATTACK			HALT			< To/From v
	[State.IDLE,	State.WALK,		State.ATTACK,	State.HALT],	# IDLE
	[State.IDLE,	State.WALK,		State.ATTACK,	State.HALT],	# WALK
	[State.ATTACK,	State.ATTACK,	State.ATTACK,	State.HALT],	# ATTACK
	[State.HALT,	State.HALT,		State.HALT,		State.HALT],	# HALT
]

const minDistance : int				= 30
const maxDistance : int				= 200

const minWalkTimer : int			= 5
const maxWalkTimer : int			= 20

const minUnstuckTimer : int			= 2
const maxUnstuckTimer : int			= 10

const refreshDelay : float			= 1.0

#
static func GetOffset() -> Vector2i:
	return Vector2i(
		randi_range(minDistance, maxDistance),
		randi_range(minDistance, maxDistance))
static func GetWalkTimer() -> float:
	return randf_range(minWalkTimer, maxWalkTimer)
static func GetUnstuckTimer() -> float:
	return randf_range(minUnstuckTimer, maxUnstuckTimer)
static func IsStuck(agent : BaseAgent) -> bool:
	return agent.lastPositions.size() >= 5 and abs(agent.lastPositions[0] - agent.lastPositions[4]) < 1
static func IsActionInProgress(agent : BaseAgent) -> bool:
	return agent.actionTimer and not agent.actionTimer.is_stopped()
static func IsAgentMoving(agent : BaseAgent):
	return agent.hasCurrentGoal
static func CanWalk(agent: BaseAgent):
	return agent.agent != null
static func GetRandomSkill(agent : BaseAgent) -> SkillData:
	return agent.skillSet[randi() % agent.skillSet.size()] if agent.skillSet.size() > 0 else null

#
static func SetState(agent : BaseAgent, state : State, force : bool = false):
	var newState : State = state if force else transitions[agent.aiState][state]

	if agent.aiState != newState:
		if IsActionInProgress(agent):
			Callback.ClearTimer(agent.actionTimer)
		if IsAgentMoving(agent):
			agent.ResetNav()

	agent.aiState = newState

static func Reset(agent : BaseAgent):
	SetState(agent, State.IDLE, true)
	Callback.StartTimer(agent.aiTimer, refreshDelay, AI.Refresh.bind(agent))

static func Refresh(agent : BaseAgent):
	if not agent:
		return
	if not WorldAgent.GetMapFromAgent(agent):
		SetState(agent, State.HALT)

	match agent.aiState:
		State.IDLE:
			StateIdle(agent)
		State.WALK:
			StateWalk(agent)
		State.ATTACK:
			StateAttack(agent)
		State.HALT:
			Callback.ClearTimer(agent.aiTimer)
			return
		_:
			Util.Assert(false, "AI state not handled")

	Callback.LoopTimer(agent.aiTimer, refreshDelay)

#
static func StateIdle(agent : BaseAgent):
	if not IsActionInProgress(agent):
		if CanWalk(agent):
			Callback.StartTimer(agent.actionTimer, GetWalkTimer(), AI.ToWalk.bind(agent))

static func StateWalk(agent : BaseAgent):
	if IsActionInProgress(agent) and IsAgentMoving(agent):
		if IsStuck(agent):
			agent.ResetNav()
			Callback.StartTimer(agent.actionTimer, GetUnstuckTimer(), AI.ToWalk.bind(agent))

static func StateAttack(agent : BaseAgent):
	var target : BaseAgent = agent.GetMostValuableAttacker()

	if not Skill.IsAlive(target):
		SetState(agent, State.IDLE, true)

	if not IsActionInProgress(agent):
		var randomSkill : SkillData = GetRandomSkill(agent)
		if Skill.IsTargetable(agent, target, randomSkill):
			ToAttack(agent, target, randomSkill)
		elif target and CanWalk(agent):
			ToChase(agent, target)

# Could be delayed, always check if agent is inside a map
static func ToWalk(agent : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		var position : Vector2i = WorldNavigation.GetRandomPositionAABB(map, agent.position, GetOffset())
		agent.WalkToward(position)
		agent.aiState = State.WALK
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, State.IDLE, false])

static func ToAttack(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if IsAgentMoving(agent):
		agent.ResetNav()
	if WorldAgent.GetMapFromAgent(agent):
		Skill.Cast(agent, target, skill)

static func ToChase(agent : BaseAgent, target : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map and Skill.IsSameMap(agent, target):
		agent.WalkToward(target.position)
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.Refresh, [agent])
