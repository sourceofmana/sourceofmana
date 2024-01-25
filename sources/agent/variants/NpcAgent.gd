extends BaseAgent
class_name NpcAgent

#
static func GetEntityType() -> EntityCommons.Type: return EntityCommons.Type.NPC

#
func Interact(caller : BaseAgent):
	if caller:
		var peerID : int = Launcher.Network.Server.GetRid(caller)
		if peerID != Launcher.Network.RidUnknown:
			var npcAgentID : int = get_rid().get_id()
			if SetState(EntityCommons.State.TRIGGER) and currentState == EntityCommons.State.TRIGGER:
				Launcher.Network.ChatAgent(npcAgentID, "Hello %s!" % caller.get_name(), peerID)

#
func _specific_process():
	var parent : Node = get_parent()
	if parent != null and parent is WorldInstance:
		AI.Update(self, parent.map)

func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	add_child.call_deferred(aiTimer)
