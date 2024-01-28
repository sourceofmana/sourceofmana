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
	pass

func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Util.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	castTimer = Timer.new()
	castTimer.set_name("CastTimer")
	castTimer.set_one_shot(true)
	add_child.call_deferred(castTimer)

	super._ready()
