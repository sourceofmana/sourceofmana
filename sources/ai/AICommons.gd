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
	PACIFIST	= 1 << 0,
	NEUTRAL		= 1 << 1,
	AGGRESSIVE	= 1 << 2,
	IMMOBILE	= 1 << 3,
	FOLLOWER	= 1 << 4,
	LEADER		= 1 << 5,
	SPAWNER		= 1 << 6,
	STEAL		= 1 << 7,
}

const behaviourNone : String				= "None"
const behaviourPacifist : String			= "Pacifist"
const behaviourNeutral : String				= "Neutral"
const behaviourAggressive : String			= "Aggressive"
const behaviourImmobile : String			= "Immobile"
const behaviourFollower : String			= "Follower"
const behaviourLeader : String				= "Leader"
const behaviourSpawner : String				= "Spawner"
const behaviourSteal : String				= "Steal"

static func GetBehaviourFlags(behaviours : PackedStringArray) -> int:
	var flags : int = Behaviour.NONE
	for behaviour in behaviours:
		match behaviour:
			behaviourNone:					flags |= Behaviour.NONE
			behaviourPacifist:				flags |= Behaviour.PACIFIST
			behaviourNeutral:				flags |= Behaviour.NEUTRAL
			behaviourAggressive:			flags |= Behaviour.AGGRESSIVE
			behaviourImmobile:				flags |= Behaviour.IMMOBILE
			behaviourFollower:				flags |= Behaviour.FOLLOWER
			behaviourLeader:				flags |= Behaviour.LEADER
			behaviourSpawner:				flags |= Behaviour.SPAWNER
			behaviourSteal:					flags |= Behaviour.STEAL
			_:								assert(false, "Behaviour flag not recognized: %s" % [behaviour])
	return flags

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
const reachDistance : float			= 500
const reachDistanceSquared : float	= reachDistance * reachDistance
const maxAttackerCount : int		= 8

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
	return agent.hasCurrentGoal and agent.aiState == State.WALK

static func IsReachable(agent : BaseAgent, target : BaseAgent) -> bool:
	return SkillCommons.IsInteractable(agent, target) and WorldNavigation.GetPathLengthSquared(agent, target.position) < reachDistanceSquared

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

# Behaviour
static func ApplyPacifistBehaviour(agent : BaseAgent) -> bool:
	if agent.aiState == State.ATTACK:
		AI.SetState(agent, State.IDLE, true)
		return true
	return false

static func ApplyNeutralBehaviour(agent : BaseAgent) -> bool:
	if agent == null or agent.agent == null:
		return false

	var target : BaseAgent = agent.GetNearbyMostValuableAttacker()
	if target:
		AI.SetState(agent, AICommons.State.ATTACK, true)
		return true
	elif agent.aiState == AICommons.State.ATTACK:
		AI.SetState(agent, AICommons.State.WALK, true)
	return false

static func ApplyAggressiveBehaviour(agent : BaseAgent) -> bool:
	if agent == null:
		return false

	var nearest : PlayerAgent = null
	var nearestSquaredDist : float = AICommons.reachDistanceSquared
	var instance : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	for player in instance.players:
		if SkillCommons.IsInteractable(agent, player):
			var currentDist : float = WorldNavigation.GetPathLengthSquared(agent, player.position)
			if currentDist < nearestSquaredDist:
				nearest = player
				nearestSquaredDist = currentDist
	if nearest:
		agent.AddAttacker(nearest)
		agent.aiState = AICommons.State.ATTACK
		return true
	return false

static func ApplyStealBehaviour(_agent : BaseAgent) -> bool:
	return false

static func ApplyFollowerBehaviour(_agent : BaseAgent) -> bool:
	return false

static func ApplyImmobileBehaviour(_agent : BaseAgent) -> bool:
	return false

static func ApplySpawnerBehaviour(_agent : BaseAgent) -> bool:
	return false
