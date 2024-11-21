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
		if pc is PlayerAgent and pc.rpcRID != NetworkCommons.RidUnknown:
			Launcher.Network.PushNotification(text, pc.rpcRID)
		elif pc is NpcAgent:
			var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(pc)
			if inst:
				Launcher.Network.Server.NotifyInstance(inst, "PushNotification", [text])

# Context sent to client
static func Chat(npc : NpcAgent, pc : BaseAgent, chat : String):
	if npc and pc and pc is PlayerAgent and pc.rpcRID != NetworkCommons.RidUnknown:
		Launcher.Network.ChatAgent(npc.get_rid().get_id(), chat, pc.rpcRID)

static func ContextText(pc : BaseAgent, author : String, text : String):
	if pc and pc is PlayerAgent and pc.rpcRID != NetworkCommons.RidUnknown:
		Launcher.Network.ContextText(author, text, pc.rpcRID)

static func ContextChoices(pc : BaseAgent, texts : PackedStringArray):
	if pc and pc is PlayerAgent and pc.rpcRID != NetworkCommons.RidUnknown:
		Launcher.Network.ContextChoice(texts, pc.rpcRID)

static func ContextContinue(pc : BaseAgent):
	if pc and pc is PlayerAgent and pc.rpcRID != NetworkCommons.RidUnknown:
		Launcher.Network.ContextContinue(pc.rpcRID)

static func ContextClose(pc : BaseAgent):
	if pc and pc is PlayerAgent and pc.rpcRID != NetworkCommons.RidUnknown:
		Launcher.Network.ContextClose(pc.rpcRID)

static func ToggleContext(pc : BaseAgent, enable : bool):
	if pc and pc is PlayerAgent and pc.rpcRID != NetworkCommons.RidUnknown:
		Launcher.Network.ToggleContext(enable, pc.rpcRID)

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

# Commands
static func Spawn(caller : BaseAgent, monsterName : String, count : int = 1, position : Vector2 = Vector2.ZERO, spawnRadius : Vector2 = Vector2(64, 64)) -> Array[MonsterAgent]:
	var agents : Array[MonsterAgent] = []
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(caller)
	if inst and inst.map:
		for i in count:
			var spawnObject : SpawnObject = SpawnObject.new()
			spawnObject.map					= inst.map
			spawnObject.type				= "Monster"
			spawnObject.name				= monsterName
			spawnObject.count				= count
			if position == Vector2.ZERO:
				spawnObject.spawn_position	= WorldNavigation.GetRandomPosition(inst.map)
			else:
				spawnObject.spawn_position	= WorldNavigation.GetRandomPositionAABB(inst.map, position, spawnRadius)
			agents.push_back(WorldAgent.CreateAgent(spawnObject, inst.id))
	return agents

static func Warp(caller : BaseAgent, mapName : String, position : Vector2):
	if caller is PlayerAgent:
		var map : WorldMap = Launcher.World.GetMap(mapName)
		if map:
			Launcher.World.Warp(caller, map, position)
