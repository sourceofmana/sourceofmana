extends Node
class_name NpcCommons

const Greetings : PackedStringArray = [
	"Hello %s!",
	"Greetings, %s.",
	"Ah, %s.",
	"Welcome.",
	"Salutations.",
	"Good to see you, %s.",
	"Ahoy!",
	"Well met, %s.",
	"Hey there.",
	"Good day.",
	"Well met."
]

static var Farewells : PackedStringArray = [
	"Goodbye, %s.",
	"Farewell.",
	"See you later, %s.",
	"Until next time.",
	"Safe travels, %s.",
	"Take care.",
	"Good journey.",
	"Until we meet again, %s.",
	"Stay safe.",
	"Goodbye for now."
]

#
static func GetRandomGreeting(nick : String) -> String:
	var greet : String = Greetings[randi() % Greetings.size()]
	return greet if greet.find("%s") == -1 else greet % [nick]

static func GetRandomFarewell(nick : String) -> String:
	var farewell : String = Farewells[randi() % Farewells.size()]
	return farewell if farewell.find("%s") == -1 else farewell % [nick]

#
static func Chat(npc : NpcAgent, pc : PlayerAgent, chat : String):
	if npc and pc:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ChatAgent(npc.get_rid().get_id(), chat, peerID)

static func ContextText(npc : NpcAgent, pc : PlayerAgent, text : String):
	if npc and pc:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ContextText(npc.get_rid().get_id(), text, peerID)

static func ContextChoices(pc : PlayerAgent, texts : PackedStringArray):
	if pc:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ContextChoice(texts, peerID)
