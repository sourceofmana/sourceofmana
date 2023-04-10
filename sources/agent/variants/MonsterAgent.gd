extends BaseAgent
class_name MonsterAgent

#
func Trigger(caller : BaseAgent):
	if caller && currentState != EntityCommons.State.DEATH:
		caller.target = self
