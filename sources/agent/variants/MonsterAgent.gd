extends BaseAgent
class_name MonsterAgent

#
func Trigger(caller : BaseAgent):
	if caller:
		# SetState(EntityCommons.State.DEAD)
		Launcher.World.RemoveAgent(self)
