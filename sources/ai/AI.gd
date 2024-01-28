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

#
static func SetState(agent : BaseAgent, state : State, force : bool = false):
	agent.aiState = state if force else transitions[agent.aiState][state]

static func Reset(agent : BaseAgent):
	agent.aiState = State.IDLE
	Util.StartTimer(agent.aiTimer, refreshDelay, AI.Refresh.bind(agent))

static func Refresh(agent : BaseAgent):
	if not agent or not agent.get_parent():
		return

	match agent.aiState:
		State.IDLE:
			StateIdle(agent)
		State.WALK:
			StateWalk(agent)
		State.ATTACK:
			StateAttack(agent)
		State.HALT:
			StateHalt(agent)

	Util.LoopTimer(agent.aiTimer, refreshDelay)

#
static func StateIdle(agent : BaseAgent):
	if not IsActionInProgress(agent):
		Util.StartTimer(agent.actionTimer, GetWalkTimer(), AI.ToWalk.bind(agent))

static func StateWalk(agent : BaseAgent):
	if IsActionInProgress(agent) and agent.hasCurrentGoal:
		if IsStuck(agent):
			agent.ResetNav()
			Util.StartTimer(agent.actionTimer, GetUnstuckTimer(), AI.ToWalk.bind(agent))

static func StateAttack(_agent : BaseAgent):
	pass

static func StateHalt(agent : BaseAgent):
	for sig in agent.aiTimer.timeout.get_connections():
		Util.RemoveCallback(agent.aiTimer.timeout, sig["callable"])

#
static func ToWalk(agent : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		var position : Vector2i = WorldNavigation.GetRandomPositionAABB(map, agent.position, GetOffset())
		agent.WalkToward(position)
		agent.aiState = State.WALK
		Util.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, State.IDLE, false])

static func ToAttack(_agent : BaseAgent):
	pass

static func ToChase(_agent : BaseAgent):
	pass
