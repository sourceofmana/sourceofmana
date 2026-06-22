extends CellScript
class_name JumpAbility

#
const JUMP_INNER_RADIUS : float = 128
const JUMP_OUTER_RADIUS : float = 256
const JUMP_DELAY : float = 1.5

#
func Execute(agent : BaseAgent):
	Callback.StartTimer(agent.actionTimer, JUMP_DELAY, JumpAbility.PerformJump.bind(agent), true)

static func PerformJump(agent : BaseAgent):
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	if inst:
		var newPos : Vector2 = WorldNavigation.GetRandomPositionRing(inst, agent.position, JUMP_INNER_RADIUS, JUMP_OUTER_RADIUS)
		if newPos != Vector2.ZERO:
			agent.position = newPos
			agent.velocity = Vector2.ZERO
			agent.currentVelocity = Vector2.ZERO
			agent.requireFullUpdate = true
			if agent is AIAgent:
				agent.ResetNav()
