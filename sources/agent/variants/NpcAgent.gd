extends BaseAgent
class_name NpcAgent

#
func Trigger(caller : BaseAgent):
	if caller:
		var peerID : int = Launcher.Network.Server.GetRid(caller)
		if peerID != Launcher.Network.RidUnknown:
			var npcAgentID : int = get_rid().get_id()
			Launcher.Network.ChatAgent(npcAgentID, "Hello %s!" % caller.agentName, peerID)
