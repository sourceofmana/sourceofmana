extends Object
class_name AICommons

#
const _transitions : Array[Array] = [
#	IDLE				WALK				ATTACK				HALT			< To/From v
	[AI.State.IDLE,		AI.State.WALK,		AI.State.ATTACK,	AI.State.HALT],	# IDLE
	[AI.State.IDLE,		AI.State.WALK,		AI.State.ATTACK,	AI.State.HALT],	# WALK
	[AI.State.ATTACK,	AI.State.ATTACK,	AI.State.ATTACK,	AI.State.HALT],	# ATTACK
	[AI.State.HALT,		AI.State.HALT,		AI.State.HALT,		AI.State.HALT],	# HALT
]

const refreshDelay : float			= 1.0

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

static func GetRandomSkill(agent : BaseAgent) -> SkillData:
	if agent.skillSet.size() > 0 and agent.skillProbaSum > 0.0:
		var randProba : float = randf_range(0.0, agent.skillProbaSum)
		for skill in agent.skillSet:
			randProba -= agent.skillProba[skill]
			if randProba <= 0.0:
				return skill
	return null

static func GetTransition(prev : AI.State, next : AI.State) -> AI.State:
	return _transitions[prev][next]
