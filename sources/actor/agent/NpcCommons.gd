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
static func PushNotification(agent : BaseAgent, text : String):
	if agent:
		if agent is PlayerAgent and agent.peerID != NetworkCommons.PeerUnknownID:
			Network.PushNotification(text, agent.peerID)
		elif agent is NpcAgent:
			var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
			if inst:
				Network.NotifyInstance(inst, "PushNotification", [text])

static func PushTracker(agent : BaseAgent, label : String, value : int, maxValue : int, unit : String = ""):
	if agent:
		if agent is PlayerAgent and agent.peerID != NetworkCommons.PeerUnknownID:
			Network.DisplayProgressionTracker(label, value, maxValue, unit, agent.peerID)
		elif agent is NpcAgent:
			var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
			if inst:
				Network.NotifyInstance(inst, "DisplayProgressionTracker", [label, value, maxValue, unit])

static func ClearTracker(agent : BaseAgent):
	if agent:
		if agent is PlayerAgent and agent.peerID != NetworkCommons.PeerUnknownID:
			Network.ClearProgressionTracker(agent.peerID)
		elif agent is NpcAgent:
			var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
			if inst:
				Network.NotifyInstance(inst, "ClearProgressionTracker", [])

# Camera
static func CameraLookAt(pc : BaseAgent, pos : Vector2):
	if pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.CameraLookAt(pos, pc.peerID)

static func CameraReset(pc : BaseAgent):
	if pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.CameraReset(pc.peerID)

# Context sent to client
static func Chat(npc : NpcAgent, pc : BaseAgent, chat : String):
	if npc and pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.ChatAgent(npc.get_rid().get_id(), chat, pc.peerID)

static func ContextText(pc : BaseAgent, author : String, text : String):
	if pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.ContextText(author, text, pc.peerID)

static func ContextChoices(pc : BaseAgent, texts : PackedStringArray):
	if pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.ContextChoice(texts, pc.peerID)

static func ContextContinue(pc : BaseAgent):
	if pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.ContextContinue(pc.peerID)

static func ContextClose(pc : BaseAgent):
	if pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.ContextClose(pc.peerID)

static func ToggleContext(pc : BaseAgent, enable : bool):
	if pc and pc is PlayerAgent and pc.peerID != NetworkCommons.PeerUnknownID:
		Network.ToggleContext(enable, pc.peerID)

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
static func Spawn(caller : BaseAgent, mobID : int, count : int = 1, position : Vector2 = Vector2.ZERO, spawnRadius : Vector2 = Vector2(64, 64)) -> Array[MonsterAgent]:
	var agents : Array[MonsterAgent] = []
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(caller)
	if inst and inst.map:
		for i in count:
			var spawnObject : SpawnObject = SpawnObject.new()
			spawnObject.map					= inst.map
			spawnObject.type				= "Monster"
			spawnObject.id					= mobID
			spawnObject.count				= count
			if position == Vector2.ZERO:
				spawnObject.spawn_position	= WorldNavigation.GetRandomPosition(inst)
			else:
				spawnObject.spawn_position	= WorldNavigation.GetRandomPositionAABB(inst, position, spawnRadius)
			agents.push_back(WorldAgent.CreateAgent(spawnObject, inst.id))
	return agents

static func Warp(caller : BaseAgent, mapID : int, position : Vector2):
	if caller is PlayerAgent:
		var map : WorldMap = Launcher.World.GetMap(mapID)
		if map:
			Launcher.World.Warp(caller, map, position)

static func WarpInstance(caller : BaseAgent, mapID : int, position : Vector2):
	if caller is PlayerAgent:
		var map : WorldMap = Launcher.World.GetMap(mapID)
		if map:
			var instanceID : int = caller.get_rid().get_id()
			if not map.instances.has(instanceID):
				map.CreateInstance(instanceID)
			Launcher.World.Warp(caller, map, position, instanceID)

# Progress
static func SetQuest(caller : BaseAgent, questID : int, state : int):
	if caller is PlayerAgent and caller.progress:
		var questData : QuestData = DB.GetQuest(questID)
		if not questData:
			return

		if caller.progress.GetQuest(questID) == ProgressCommons.UnknownProgress:
			PushNotification(caller, "Quest Started: " + questData.name)
		caller.progress.SetQuest(questID, state)
		if state == ProgressCommons.CompletedProgress:
			PushNotification(caller, "Quest Completed: " + questData.name)

static func AddBestiary(caller : BaseAgent, monsterID : int, count : int):
	if caller is PlayerAgent and caller.progress:
		var entityData : EntityData = DB.GetEntity(monsterID)
		if entityData:
			caller.progress.AddBestiary(monsterID, count)

# Inventory
static func AddItem(caller : BaseAgent, itemID : int, count : int = 1, customfield : String = "") -> bool:
	if caller is PlayerAgent and caller.inventory:
		var cell : ItemCell = DB.GetItem(itemID, customfield)
		if cell:
			return caller.inventory.AddItem(cell, count)
	return false

static func RemoveItem(caller : BaseAgent, itemID : int, count : int = 1, customfield : String = "") -> bool:
	if caller is PlayerAgent and caller.inventory:
		var cell : ItemCell = DB.GetItem(itemID, customfield)
		if cell:
			return caller.inventory.RemoveItem(cell, count)
	return false

# Skills
static func TeachSkill(caller : BaseAgent, skillID : int, level : int = 1) -> bool:
	if caller is PlayerAgent and caller.progress:
		var cell : SkillCell = DB.GetSkill(skillID)
		if cell:
			caller.progress.AddSkill(cell, 1.0, level)
			return true
	return false

# Karma
static func AddKarma(caller : BaseAgent, points : int) -> bool:
	if caller is PlayerAgent and caller.stat:
		caller.stat.karma += points
	return false

# Gain
static func AddExp(caller : BaseAgent, value : int):
	if caller is PlayerAgent and caller.stat and value > 0:
		caller.stat.AddExperience(value)

static func AddGP(caller : BaseAgent, value : int):
	if caller is PlayerAgent and caller.stat and value > 0:
		caller.stat.AddGP(value)
