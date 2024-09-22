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
	Callback.StartTimer(agent.aiTimer, AICommons.RefreshDelayMin, AI.Refresh.bind(agent))

static func Refresh(agent : AIAgent):
	if not ActorCommons.IsAlive(agent) or not WorldAgent.GetInstanceFromAgent(agent):
		SetState(agent, AICommons.State.HALT)
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
			Callback.ClearTimer(agent.aiTimer)
			return
		_:
			Util.Assert(false, "AI state not handled")

	Callback.LoopTimer(agent.aiTimer, agent.aiRefreshDelay)

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
	for cat in agent.followers:
		for follower in agent.followers[cat]:
			AI.Refresh(follower)

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
	else: # Has target and action is in progress
		if not ActorCommons.IsAlive(target) or (AICommons.IsAgentMoving(agent) and not agent.currentGoal):
			Reset(agent)

# Could be delayed, always check if agent is inside a map
static func ToWalk(agent : AIAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		SetState(agent, AICommons.State.WALK, true)
		var position : Vector2i
		if agent.leader != null:
			position = WorldNavigation.GetRandomPositionAABB(map, agent.leader.position, AICommons.GetOffset())
			agent.SetNodeGoal(agent.leader, position)
		else:
			position = WorldNavigation.GetRandomPositionAABB(map, agent.position, AICommons.GetOffset())
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
