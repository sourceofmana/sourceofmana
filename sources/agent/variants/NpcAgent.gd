extends BaseAgent
class_name NpcAgent

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.NPC

#
func Interact(caller : BaseAgent):
	if caller:
		var peerID : int = Launcher.Network.Server.GetRid(caller)
		if peerID != NetworkCommons.RidUnknown:
			var npcAgentID : int = get_rid().get_id()
			if SetState(ActorCommons.State.TRIGGER) and state == ActorCommons.State.TRIGGER:
				Launcher.Network.ChatAgent(npcAgentID, "Hello %s!" % caller.nick, peerID)

#
func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Callback.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	super._ready()
