extends BaseAgent
class_name NpcAgent

#
func Trigger(caller : BaseAgent):
	if caller:
		Launcher.Network.ChatAgent(get_rid().get_id(), "Hello!", caller.get_rid().get_id())
