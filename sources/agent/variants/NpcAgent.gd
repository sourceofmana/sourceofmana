extends BaseAgent
class_name NpcAgent

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.NPC

static var Greetings = [
	"Hello %s!",
	"Greetings, %s!",
	"Ah, %s!",
	"Welcome, %s!",
	"Salutations, %s!",
	"Good to see you, %s!",
	"Ahoy, %s!",
	"Well met, %s!",
	"Hail, %s!",
	"Hey %s!",
	"Good day, %s!",
	"%s, well met!"
]

static func GetRandomGreets(actor : Actor) -> String:
	return Greetings[randi() % Greetings.size()] % [actor.nick]

#
func Interact(_actor : Actor): pass # Should be defined per NPC

func Trigger() -> bool:
	return SetState(ActorCommons.State.TRIGGER) and state == ActorCommons.State.TRIGGER

func Greets(actor : BaseAgent):
	if actor:
		var peerID : int = Launcher.Network.Server.GetRid(actor)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ChatAgent(get_rid().get_id(), NpcAgent.GetRandomGreets(actor), peerID)

#
func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Callback.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	super._ready()
