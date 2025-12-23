extends Object
class_name AICommons

#
enum State
{
	IDLE = 0,
	WALK,
	ATTACK,
	HALT,
	COUNT
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
const STATE_TRANSITIONS : PackedByteArray = [
#	IDLE            WALK            ATTACK          HALT        < To/From v
# IDLE
	State.IDLE,     State.WALK,     State.ATTACK,   State.HALT, # IDLE
# WALK
	State.IDLE,     State.WALK,     State.ATTACK,   State.HALT, # WALK
# ATTACK
	State.ATTACK,   State.ATTACK,   State.ATTACK,   State.HALT, # ATTACK
# HALT
	State.HALT,     State.HALT,     State.HALT,     State.HALT, # HALT
]

const MinRefreshDelay : float		= 1.0
const MaxRefreshDelay : float		= 5.0
const MinWalkTimer : int			= 5
const MaxWalkTimer : int			= 20
const MinUnstuckTimer : int			= 2
const MaxUnstuckTimer : int			= 10

const MinOffsetDistance : int		= 30
const MaxOffsetDistance : int		= 200
const MaxOffsetVector : Vector2i	= Vector2i(MaxOffsetDistance, MaxOffsetDistance)
const FleeDistance : float			= 200
const ReachDistance : float			= 400
const ReachDistanceSquared : float	= ReachDistance * ReachDistance
const MaxAttackerCount : int		= 8
const WanderDistanceSquared : float	= MaxOffsetDistance * MaxOffsetDistance
const EnableAvoidance : bool		= false

#
static func GeRandomtOffset() -> Vector2i:
	return Vector2i(
		randi_range(MinOffsetDistance, MaxOffsetDistance),
		randi_range(MinOffsetDistance, MaxOffsetDistance))

static func GetWalkTimer() -> float:
	return randf_range(MinWalkTimer, MaxWalkTimer)

static func GetUnstuckTimer() -> float:
	return randf_range(MinUnstuckTimer, MaxUnstuckTimer)

static func IsStuck(agent : AIAgent) -> bool:
	return agent.lastPositions.size() >= 5 and abs(agent.lastPositions[0] - agent.lastPositions[4]) < 1

static func IsActionInProgress(agent : AIAgent) -> bool:
	return agent.actionTimer and not agent.actionTimer.is_stopped()

static func IsAgentMoving(agent : AIAgent):
	return agent.hasCurrentGoal

static func IsReachable(agent : AIAgent, target : BaseAgent) -> bool:
	return SkillCommons.IsInteractable(agent, target) and WorldNavigation.GetDistanceSquared(agent, target.position) < ReachDistanceSquared

static func CanWalk(agent: AIAgent):
	return agent.agent != null

static func GetRandomSkill(agent : AIAgent) -> SkillCell:
	if agent.progress.probaSum > 0.0:
		var randProba : float = randf_range(0.0, agent.progress.probaSum)
		for skill in agent.progress.skills:
			randProba -= agent.progress.skillProbas[skill]
			if randProba <= 0.0:
				return DB.GetSkill(skill)
	return null

static func HasExpiredNodeGoal(agent : AIAgent):
	return agent.hasNodeGoal and (agent.nodeGoal == null or (agent.nodeGoal is BaseAgent and not (ActorCommons.IsAlive(agent.nodeGoal) and SkillCommons.IsSameMap(agent, agent.nodeGoal))))

# Behaviour
static func ApplyPacifistBehaviour(agent : AIAgent) -> bool:
	if agent.aiState == State.ATTACK:
		AI.SetState(agent, State.IDLE, true)
		return true
	return false

static func ApplyNeutralBehaviour(agent : AIAgent) -> bool:
	if agent == null or agent.agent == null:
		return false

	var target : BaseAgent = agent.GetNearbyMostValuableAttacker()
	if target:
		if agent.aiState != State.ATTACK or agent.nodeGoal != target:
			AI.SetState(agent, State.ATTACK, true)
		return true
	elif agent.aiState == State.ATTACK:
		AI.Reset(agent)
	return false

static func ApplyAggressiveBehaviour(agent : AIAgent) -> bool:
	if agent == null:
		return false

	var nearest : PlayerAgent = null
	var nearestSquaredDist : float = ReachDistanceSquared
	var instance : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	for player in instance.players:
		if SkillCommons.IsInteractable(agent, player):
			var currentDist : float = WorldNavigation.GetDistanceSquared(agent, player.position)
			if currentDist < nearestSquaredDist:
				nearest = player
				nearestSquaredDist = currentDist
	if nearest:
		agent.AddAttacker(nearest)
		if agent.aiState != State.ATTACK or agent.nodeGoal != nearest:
			AI.SetState(agent, State.ATTACK, true)
		return true

	AI.Reset(agent)
	return false

static func ApplyStealBehaviour(agent : AIAgent) -> bool:
	if not IsActionInProgress(agent):
		var instance : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
		if instance:
			var nearest : Drop = null
			var nearestDist : float = INF
			for dropIdx in instance.drops:
				var drop : Drop = instance.drops[dropIdx]
				if drop:
					var dist : float = WorldNavigation.GetDistanceSquared(agent, drop.position)
					if dist < nearestDist and dist < ReachDistanceSquared:
						nearest = drop
						nearestDist = dist
			if nearest:
				if nearestDist < ActorCommons.PickupSquaredDistance:
					WorldDrop.PickupDrop(nearest.get_instance_id(), agent)
				else:
					AI.SetState(agent, State.WALK, true)
					agent.currentWalkSpeed = Vector2(agent.stat.current.walkSpeed, agent.stat.current.walkSpeed)
					agent.SetNodeGoal(nearest, nearest.position)
				return true

	return false

static func ApplyFollowerBehaviour(agent : AIAgent) -> bool:
	if not IsActionInProgress(agent):
		if agent.leader != null:
			if agent.leader.aiState == State.ATTACK and agent.aiState == State.IDLE:
				AI.SetState(agent, State.WALK, true)
				agent.SetNodeGoal(agent.leader, agent.leader.position)
				return true
	return false

static func ApplyImmobileBehaviour(_agent : AIAgent) -> bool:
	return false # Nothing to handle here

static func ApplySpawnerBehaviour(agent : AIAgent) -> bool:
	var nbSpawned : int = 0
	for spawn in agent.data._spawns:
		var toSpawn : int = agent.data._spawns[spawn]
		if spawn in agent.followers:
			toSpawn -= agent.followers[spawn].size()
		else:
			agent.followers[spawn] = []
		if toSpawn > 0:
			var instance : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
			if instance:
				for mob in instance.mobs:
					if mob.leader == null and mob.aiBehaviour & Behaviour.FOLLOWER and mob.data._id == spawn and mob.spawnInfo.is_persistant == false:
						agent.AddFollower(mob)
						toSpawn -= 1
					if toSpawn == 0:
						break

		if toSpawn > 0:
			var spawnedAgents : Array[MonsterAgent] = NpcCommons.Spawn(agent, spawn, toSpawn, agent.position, GeRandomtOffset())
			for spawnedAgent in spawnedAgents:
				agent.AddFollower(spawnedAgent)
			nbSpawned += spawnedAgents.size()

	return nbSpawned > 0
