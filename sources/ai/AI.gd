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
static func SetState(agent : BaseAgent, state : State, force : bool = false):
	var newState : State = state if force else AICommons.GetTransition(agent.aiState, state)
	if agent.aiState != newState:
		agent.aiState = newState
		if AICommons.IsActionInProgress(agent):
			Callback.ClearTimer(agent.actionTimer)
		if AICommons.IsAgentMoving(agent):
			agent.ResetNav()

static func Reset(agent : BaseAgent):
	SetState(agent, State.IDLE, true)
	Callback.StartTimer(agent.aiTimer, AICommons.refreshDelay, AI.Refresh.bind(agent))

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

	Callback.LoopTimer(agent.aiTimer, AICommons.refreshDelay)

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
	if not SkillCommons.IsAlive(target):
		SetState(agent, State.IDLE, true)
	elif not AICommons.IsActionInProgress(agent):
		agent.skillSelected = AICommons.GetRandomSkill(agent)
		if not agent.skillSelected:
			ToFlee(agent, target)
		elif SkillCommons.IsTargetable(agent, target, agent.skillSelected):
			ToAttack(agent, target)
		elif target and AICommons.CanWalk(agent):
			ToChase(agent, target)

# Could be delayed, always check if agent is inside a map
static func ToWalk(agent : BaseAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		var position : Vector2i = WorldNavigation.GetRandomPositionAABB(map, agent.position, AICommons.GetOffset())
		agent.WalkToward(position)
		agent.aiState = State.WALK
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, State.IDLE])

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
		agent.WalkToward(fleePosition)
		agent.aiState = State.WALK
		Callback.OneShotCallback(agent.agent.navigation_finished, AI.SetState, [agent, State.IDLE])
