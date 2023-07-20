extends BaseAgent
class_name MonsterAgent

#
func Trigger(caller : BaseAgent):
	caller.target = self
	Combat.Cast(caller)
