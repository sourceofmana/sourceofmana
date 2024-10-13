extends Object
class_name AI

#
static func SetState(agent : AIAgent, state : AICommons.State, force : bool = false):
	var newState : AICommons.State = state if force else AICommons.GetTransition(agent.aiState, state)
	if agent.aiState != newState:
		agent.aiState = newState
		if AICommons.IsActionInProgress(agent):
			Callback.ClearTimer(agent.actionTimer)
		if AICommons.IsAgentMoving(agent):
			if agent.skillSelected:
				agent.skillSelected = null
			else:
				agent.ResetNav()
		if agent.agent:
			agent.agent.avoidance_enabled = agent.aiState == AICommons.State.ATTACK

static func Reset(agent : AIAgent):
	SetState(agent, AICommons.State.IDLE, true)
	agent.ResetNav()
	Callback.StartTimer(agent.aiTimer, agent.aiRefreshDelay, Refresh.bind(agent))

static func Stop(agent : AIAgent):
	SetState(agent, AICommons.State.HALT)

static func Refresh(agent : AIAgent):
	if not ActorCommons.IsAlive(agent) or not WorldAgent.GetInstanceFromAgent(agent):
		Stop(agent)
	else:
		if AICommons.HasExpiredNodeGoal(agent):
			Reset(agent)
		HandleBehaviour(agent)

	match agent.aiState:
		AICommons.State.IDLE:
			StateIdle(agent)
		AICommons.State.WALK:
			StateWalk(agent)
		AICommons.State.ATTACK:
			StateAttack(agent)
		AICommons.State.HALT:
			if agent.agent:
				agent.agent.avoidance_layers = 0
			Callback.ClearTimer(agent.aiTimer)
			return
		_:
			assert(false, "AI state not handled")

	Callback.LoopTimer(agent.aiTimer, AICommons.MinRefreshDelay if agent.aiState == AICommons.State.ATTACK else agent.aiRefreshDelay)

static func HandleBehaviour(agent : AIAgent):
	var handled : bool = false

	# Check if should idle
	if not handled and agent.aiBehaviour & AICommons.Behaviour.SPAWNER:
		handled = AICommons.ApplySpawnerBehaviour(agent)
	if not handled and agent.aiBehaviour & AICommons.Behaviour.IMMOBILE:
		handled = AICommons.ApplyImmobileBehaviour(agent)

	# Check if should attack, either one of those
	if not handled and agent.aiBehaviour & AICommons.Behaviour.PACIFIST:
		handled = AICommons.ApplyPacifistBehaviour(agent)
	elif not handled and agent.aiBehaviour & AICommons.Behaviour.NEUTRAL:
		handled = AICommons.ApplyNeutralBehaviour(agent)
	elif not handled and agent.aiBehaviour & AICommons.Behaviour.AGGRESSIVE:
		handled = AICommons.ApplyAggressiveBehaviour(agent)

	# Check if should walk
	if not handled and agent.aiBehaviour & AICommons.Behaviour.STEAL:
		handled = AICommons.ApplyStealBehaviour(agent)
	if not handled and agent.aiBehaviour & AICommons.Behaviour.FOLLOWER:
		handled = AICommons.ApplyFollowerBehaviour(agent)

#
static func StateIdle(agent : AIAgent):
	if not AICommons.IsActionInProgress(agent):
		if AICommons.CanWalk(agent):
			Callback.StartTimer(agent.actionTimer, AICommons.GetWalkTimer(), AI.ToWalk.bind(agent))

static func StateWalk(agent : AIAgent):
	if not AICommons.IsAgentMoving(agent) or AICommons.IsStuck(agent):
		Reset(agent)

static func StateAttack(agent : AIAgent):
	var target : BaseAgent = agent.GetMostValuableAttacker()
	if not target:
		Reset(agent)
	elif not AICommons.IsActionInProgress(agent):
		agent.skillSelected = AICommons.GetRandomSkill(agent)
		if not agent.skillSelected:
			if AICommons.CanWalk(agent):
				ToFlee(agent, target)
		elif SkillCommons.IsTargetable(agent, target, agent.skillSelected):
			ToAttack(agent, target)
		elif target:
			if AICommons.CanWalk(agent):
				ToChase(agent, target)
		else:
			Reset(agent)
	else: # Has target and is moving toward a Node2D goal
		if not ActorCommons.IsAlive(target) or (AICommons.IsAgentMoving(agent) and agent.nodeGoal == null):
			Reset(agent)

# Could be delayed, always check if agent is inside a map
static func ToWalk(agent : AIAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		SetState(agent, AICommons.State.WALK, true)
		var position : Vector2i = agent.position
		if agent.leader != null:
			position = WorldNavigation.GetRandomPositionAABB(map, agent.leader.position, AICommons.MaxOffsetVector)
			agent.SetNodeGoal(agent.leader, position)
		else:
			# Check if agent is within its spawn wandering zone
			var deltaPosition: Vector2 = agent.position - Vector2(agent.spawnInfo.spawn_position)
			if agent.spawnInfo.is_global or \
			abs(deltaPosition.x) <= agent.spawnInfo.spawn_offset.x and abs(deltaPosition.y) <= agent.spawnInfo.spawn_offset.y or \
			(deltaPosition - Vector2(agent.spawnInfo.spawn_offset)).length_squared() <= AICommons.WanderDistanceSquared:
				position = WorldNavigation.GetRandomPositionAABB(map, agent.position, AICommons.MaxOffsetVector)
			else:
				position = WorldNavigation.GetRandomPositionAABB(map, agent.spawnInfo.spawn_position, agent.spawnInfo.spawn_offset)
			agent.SetNodeGoal(agent, position)
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, AICommons.State.IDLE])

static func ToAttack(agent : AIAgent, target : BaseAgent):
	if AICommons.IsAgentMoving(agent):
		agent.ResetNav()
	if WorldAgent.GetMapFromAgent(agent):
		Skill.Cast(agent, target, agent.skillSelected)

static func ToChase(agent : AIAgent, target : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map and SkillCommons.IsSameMap(agent, target):
		agent.SetNodeGoal(target, target.position)
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.Refresh, [agent])

static func ToFlee(agent : AIAgent, target : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map and SkillCommons.IsSameMap(agent, target):
		var fleePosition : Vector2 = agent.position - agent.position.direction_to(target.position) * AICommons.FleeDistance
		SetState(agent, AICommons.State.WALK, true)
		agent.SetNodeGoal(target, fleePosition)
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, AICommons.State.IDLE])
