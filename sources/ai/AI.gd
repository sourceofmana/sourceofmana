extends Object
class_name AI

#
static func SetState(agent : BaseAgent, state : AICommons.State, force : bool = false):
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

static func Reset(agent : BaseAgent):
	SetState(agent, AICommons.State.IDLE, true)
	Callback.StartTimer(agent.aiTimer, AICommons.refreshDelay, AI.Refresh.bind(agent))

static func Refresh(agent : BaseAgent):
	if not ActorCommons.IsAlive(agent) or not WorldAgent.GetInstanceFromAgent(agent):
		SetState(agent, AICommons.State.HALT)
	else:
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

	Callback.LoopTimer(agent.aiTimer, AICommons.refreshDelay)

static func HandleBehaviour(agent : BaseAgent):
	var handled : bool = false

	# Check if should attack
	if not handled and agent.behaviour & AICommons.Behaviour.PACIFIST:
		handled = AICommons.ApplyPacifistBehaviour(agent)
	elif not handled and agent.behaviour & AICommons.Behaviour.NEUTRAL:
		handled = AICommons.ApplyNeutralBehaviour(agent)
	elif not handled and agent.behaviour & AICommons.Behaviour.AGGRESSIVE:
		handled = AICommons.ApplyAggressiveBehaviour(agent)

	# Check if should walk
	elif not handled and agent.behaviour & AICommons.Behaviour.STEAL:
		handled = AICommons.ApplyStealBehaviour(agent)
	elif not handled and agent.behaviour & AICommons.Behaviour.FOLLOWER:
		handled = AICommons.ApplyFollowerBehaviour(agent)

	# Check if should idle
	if not handled and agent.behaviour & AICommons.Behaviour.SPAWNER:
		handled = AICommons.ApplySpawnerBehaviour(agent)
	elif not handled and agent.behaviour & AICommons.Behaviour.IMMOBILE:
		handled = AICommons.ApplyImmobileBehaviour(agent)

#
static func StateIdle(agent : BaseAgent):
	if not AICommons.IsActionInProgress(agent):
		if AICommons.CanWalk(agent):
			Callback.StartTimer(agent.actionTimer, AICommons.GetWalkTimer(), AI.ToWalk.bind(agent))

static func StateWalk(agent : BaseAgent):
	if AICommons.IsActionInProgress(agent) and AICommons.IsAgentMoving(agent):
		if AICommons.IsStuck(agent):
			agent.ResetNav()
			Callback.StartTimer(agent.actionTimer, AICommons.GetUnstuckTimer(), AI.ToWalk.bind(agent))

static func StateAttack(agent : BaseAgent):
	var target : BaseAgent = agent.GetMostValuableAttacker()
	if not target:
		SetState(agent, AICommons.State.IDLE, true)
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

# Could be delayed, always check if agent is inside a map
static func ToWalk(agent : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		var position : Vector2i = WorldNavigation.GetRandomPositionAABB(map, agent.position, AICommons.GetOffset())
		SetState(agent, AICommons.State.WALK, true)
		agent.WalkToward(position)
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, AICommons.State.IDLE])

static func ToAttack(agent : BaseAgent, target : BaseAgent):
	if AICommons.IsAgentMoving(agent):
		agent.ResetNav()
	if WorldAgent.GetMapFromAgent(agent):
		Skill.Cast(agent, target, agent.skillSelected)

static func ToChase(agent : BaseAgent, target : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map and SkillCommons.IsSameMap(agent, target):
		agent.WalkToward(target.position)
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.Refresh, [agent])

static func ToFlee(agent : BaseAgent, target : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map and SkillCommons.IsSameMap(agent, target):
		var fleePosition : Vector2 = agent.position - agent.position.direction_to(target.position) * AICommons.fleeDistance
		SetState(agent, AICommons.State.WALK, true)
		agent.WalkToward(fleePosition)
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, AICommons.State.IDLE])
