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

# Display
static func PushNotification(pc : BaseAgent, text : String):
	if pc:
		if pc is PlayerAgent:
			var peerID : int = Launcher.Network.Server.GetRid(pc)
			if peerID != NetworkCommons.RidUnknown:
				Launcher.Network.PushNotification(text, peerID)
		elif pc is NpcAgent:
			var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(pc)
			if inst:
				Launcher.Network.Server.NotifyInstance(inst, "PushNotification", [text])

# Context sent to client
static func Chat(npc : NpcAgent, pc : BaseAgent, chat : String):
	if npc and pc and pc is PlayerAgent:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ChatAgent(npc.get_rid().get_id(), chat, peerID)

static func ContextText(pc : BaseAgent, author : String, text : String):
	if pc and pc is PlayerAgent:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ContextText(author, text, peerID)

static func ContextChoices(pc : BaseAgent, texts : PackedStringArray):
	if pc and pc is PlayerAgent:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ContextChoice(texts, peerID)

static func ContextContinue(pc : BaseAgent):
	if pc and pc is PlayerAgent:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ContextContinue(peerID)

static func ContextClose(pc : BaseAgent):
	if pc and pc is PlayerAgent:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ContextClose(peerID)

static func ToggleContext(pc : BaseAgent, enable : bool):
	if pc and pc is PlayerAgent:
		var peerID : int = Launcher.Network.Server.GetRid(pc)
		if peerID != NetworkCommons.RidUnknown:
			Launcher.Network.ToggleContext(enable, peerID)

static func GetRandomGreeting(nick : String) -> String:
	var greet : String = Greetings[randi() % Greetings.size()]
	return greet if greet.find("%s") == -1 else greet % [nick]

static func GetRandomFarewell(nick : String) -> String:
	var farewell : String = Farewells[randi() % Farewells.size()]
	return farewell if farewell.find("%s") == -1 else farewell % [nick]

# Context received from client
static func TryCloseContext(pc : BaseAgent):
	if pc and pc is PlayerAgent and pc.ownScript and not pc.ownScript.IsWaiting():
		pc.ownScript.ToggleWindow(false)
		pc.ClearScript()

# Timer
static func AddTimer(caller : BaseAgent, delay : float, callback : Callable):
	if caller and caller.ownScript:
		var newTimer : Timer = Callback.SelfDestructTimer(caller, delay, caller.ownScript.TimeOut, [callback])
		if newTimer:
			caller.ownScript.timerCount += 1
		return newTimer
	return null
