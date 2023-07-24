extends BaseAgent
class_name MonsterAgent

#
func Damage(caller : BaseAgent):
	caller.target = self
	Combat.Cast(caller)
