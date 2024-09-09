extends Object
class_name AICommons

#
enum State
{
	IDLE = 0,
	WALK,
	ATTACK,
	HALT,
}

enum Behaviour
{
	NONE		= 0,
	NEUTRAL		= 1 << 0,
	AGGRESSIVE	= 1 << 1,
	IMMOBILE	= 1 << 2,
	LEADER		= 1 << 3,
	FOLLOWER	= 1 << 4,
	SPAWNER		= 1 << 5,
	STEAL		= 1 << 6,
}

#
const _transitions : Array[Array] = [
#	IDLE				WALK			ATTACK			HALT			< To/From v
	[State.IDLE,		State.WALK,		State.ATTACK,	State.HALT],	# IDLE
	[State.IDLE,		State.WALK,		State.ATTACK,	State.HALT],	# WALK
	[State.ATTACK,		State.ATTACK,	State.ATTACK,	State.HALT],	# ATTACK
	[State.HALT,		State.HALT,		State.HALT,		State.HALT],	# HALT
]

const refreshDelay : float			= 1.0
const fleeDistance : float			= 200

#
static func GetOffset() -> Vector2i:
	const minDistance : int				= 30
	const maxDistance : int				= 200
	return Vector2i(
		randi_range(minDistance, maxDistance),
		randi_range(minDistance, maxDistance))

static func GetWalkTimer() -> float:
	const minWalkTimer : int			= 5
	const maxWalkTimer : int			= 20
	return randf_range(minWalkTimer, maxWalkTimer)

static func GetUnstuckTimer() -> float:
	const minUnstuckTimer : int			= 2
	const maxUnstuckTimer : int			= 10
	return randf_range(minUnstuckTimer, maxUnstuckTimer)

static func IsStuck(agent : BaseAgent) -> bool:
	return agent.lastPositions.size() >= 5 and abs(agent.lastPositions[0] - agent.lastPositions[4]) < 1

static func IsActionInProgress(agent : BaseAgent) -> bool:
	return agent.actionTimer and not agent.actionTimer.is_stopped()

static func IsAgentMoving(agent : BaseAgent):
	return agent.hasCurrentGoal

static func CanWalk(agent: BaseAgent):
	return agent.agent != null

static func GetRandomSkill(agent : BaseAgent) -> SkillCell:
	if agent.skillSet.size() > 0 and agent.skillProbaSum > 0.0:
		var randProba : float = randf_range(0.0, agent.skillProbaSum)
		for skill in agent.skillSet:
			randProba -= agent.skillProba[skill]
			if randProba <= 0.0:
				return skill
	return null

static func GetTransition(prev : State, next : State) -> State:
	return _transitions[prev][next]
