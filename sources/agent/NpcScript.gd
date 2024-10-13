extends Object
class_name NpcScript

# Script variables
var npc : NpcAgent					= null
var own : BaseAgent					= null

var steps : Array[Dictionary]		= []
var step : int						= 0
var timerCount : int				= 0
var isWaitingForChoice : bool		= false
var windowToggled : bool			= false

# NPC & own script liaison
func CallGlobal(scriptFunc : String):
	if HasGlobal(scriptFunc):
		npc.ownScript.call_deferred(scriptFunc)
	else:
		assert(false, "Could not retrieve this NPC global function: %s." % scriptFunc)

func HasGlobal(scriptFunc : String) -> bool:
	return npc and npc.ownScript and npc.ownScript.has_method(scriptFunc)

func GetGlobal(scriptFunc : String) -> Callable:
	if HasGlobal(scriptFunc):
		var callable = npc.ownScript.get(scriptFunc)
		if callable is Callable:
			return callable
	assert(false, "Could not retrieve this NPC global function: %s." % scriptFunc)
	return Callable()

func Trigger() -> bool:
	if npc and npc.SetState(ActorCommons.State.TRIGGER):
		CallGlobal("OnTrigger")
		return true
	return false

func IsTriggering() -> bool:
	return ActorCommons.IsTriggering(npc)

# Monster
func Spawn(monsterName : String, count : int = 1, position : Vector2 = Vector2.ZERO, spawnRadius : Vector2 = Vector2(64, 64)) -> Array[MonsterAgent]:
	return NpcCommons.Spawn(npc, monsterName, count, position, spawnRadius)

func MonsterCount():
	var count : int = 0
	if own:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(own)
		if inst:
			count = inst.mobs.size()
	return count

func AliveMonsterCount() -> int:
	var count : int = 0
	if own:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(own)
		if inst:
			for mob in inst.mobs:
				if ActorCommons.IsAlive(mob):
					count += 1
	return count

func IsMonsterAlive(monsterName : String) -> bool:
	if own:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(own)
		if inst:
			for mob in inst.mobs:
				if mob and mob.nick == monsterName and ActorCommons.IsAlive(mob):
					return true
	return false

func KillMonsters():
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(own)
	if inst:
		for mob in inst.mobs:
			mob.stat.SetHealth(-mob.stat.current.maxHealth)

# Players
func AlivePlayerCount() -> int:
	var count : int = 0
	if own:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(own)
		if inst:
			for player in inst.players:
				if ActorCommons.IsAlive(player):
					count += 1
	return count

# Warp
func Warp(mapName : String, position : Vector2):
	NpcCommons.Warp(own, mapName, position)

# Quest
func SetQuest(questID : int, state : int):
	if own and own.progress:
		if own.progress.GetQuest(questID) == ProgressCommons.UnknownProgress:
			Notification("Quest Started: " + ProgressCommons.QuestNames[questID])
		own.progress.SetQuest(questID, state)
		if state == ProgressCommons.CompletedProgress:
			Notification("Quest Completed: " + ProgressCommons.QuestNames[questID])

func GetQuest(questID : int) -> int:
	return own.progress.GetQuest(questID) if own and own.progress else ProgressCommons.UnknownProgress

# Display
func Notification(text : String):
	NpcCommons.PushNotification(own, text)

# Dialogue
func Mes(mes : String):
	steps.append({"text": mes})

func Choice(mes : String, callable : Callable = Callback.Empty):
	if steps.is_empty():
		steps.append({"choices": []})

	var dialogueStep : Dictionary = steps[steps.size() - 1]
	if not dialogueStep.has("choices"):
		dialogueStep["choices"] = []

	dialogueStep["choices"].append({"text": mes, "action": callable})

func Chat(mes : String):
	if npc != own:
		NpcCommons.Chat(npc, own, mes)

func Greeting():
	if npc != own:
		NpcCommons.Chat(npc, own, NpcCommons.GetRandomGreeting(own.nick))

func Farewell():
	if npc != own:
		NpcCommons.Chat(npc, own, NpcCommons.GetRandomFarewell(own.nick))

# Timer
func AddTimer(caller : BaseAgent, delay : float, callback : Callable, timerName = "") -> Timer:
	if caller and caller.ownScript:
		var newTimer : Timer = null if timerName.is_empty() else caller.get_node_or_null(timerName)
		if newTimer:
			newTimer.start(delay)
		else:
			newTimer = Callback.SelfDestructTimer(caller, delay, caller.ownScript.TimeOut, [callback], timerName)
			if newTimer:
				caller.ownScript.timerCount += 1
		return newTimer
	return null

func TimeOut(callback : Callable):
	timerCount -= 1
	Callback.TriggerCallback(callback)
	if own and IsDone():
		own.ClearScript()

func ClearTimer(timer : Timer):
	if timer and not timer.is_stopped() and not timer.is_queued_for_deletion():
		timer.stop()
		timer.queue_free()
		timerCount -= 1
		if own and IsDone():
			own.ClearScript()

# Inventory
func HasItem(itemID : int, count : int = 1) -> bool:
	if own is PlayerAgent:
		var cell : BaseCell = DB.GetItem(itemID)
		return own.inventory.HasItem(cell, count) if cell else false
	return false

func HasItemsSpace(items : Array) -> bool:
	var totalCount : int = 0
	for item in items:
		var itemCount : int = 1
		var cell : BaseCell = null
		if item is Array:
			assert(item.size() == 2, "Wrong format to check user inventory space")
			if item.size() == 2:
				cell = DB.GetItem(item[0])
				itemCount = item[1]
		elif item is int:
			cell = DB.GetItem(item)
		else:
			assert(false, "Argument given is not an item, could not verify if the inventory has enough space for this")
			return false

		if cell:
			totalCount += 1 if cell.stackable else itemCount
	return HasSpace(totalCount)

func HasSpace(itemCount : int) -> bool:
	return own.inventory.HasSpace(itemCount) if own is PlayerAgent else false

func AddItem(itemID : int, count : int = 1) -> bool:
	if own is PlayerAgent:
		var cell : BaseCell = DB.GetItem(itemID)
		return own.inventory.AddItem(cell, count) if cell else false
	return false

func RemoveItem(itemID : int, count : int = 1) -> bool:
	if own is PlayerAgent:
		var cell : BaseCell = DB.GetItem(itemID)
		return own.inventory.RemoveItem(cell, count) if cell else false
	return false

# Money & Experience
func AddExp(value : int):
	if value > 0 and own is PlayerAgent and own.stat:
		own.stat.AddExperience(value)

func AddGP(value : int):
	if value > 0 and own is PlayerAgent and own.stat:
		own.stat.AddGP(value)

# Interaction logic
func ToggleWindow(toggle : bool):
	if windowToggled != toggle:
		windowToggled = toggle
		NpcCommons.ToggleContext(own, windowToggled)

func InteractChoice(choiceId : int):
	if not isWaitingForChoice:
		return

	var dialogueStep : Dictionary = steps[step]
	if choiceId < dialogueStep["choices"].size():
		var choice : Dictionary = dialogueStep["choices"][choiceId]
		NpcCommons.ContextText(own, own.nick, choice["text"])
		if choice.has("action"):
			isWaitingForChoice = false
			step = 0
			steps.clear()
			choice["action"].call()

		ApplyStep()

func ApplyStep():
	if isWaitingForChoice:
		pass # Skip the current step if we are waiting for a player choice
	elif step < steps.size():
		ToggleWindow(true)

		var dialogueStep : Dictionary = steps[step]
		if dialogueStep.has("text"):
			NpcCommons.ContextText(own, npc.nick, dialogueStep["text"])

		if dialogueStep.has("choices"):
			var choices : PackedStringArray = []
			for choice in dialogueStep["choices"]:
				if choice.has("text"):
					choices.append(choice["text"])
			if choices.size() > 0:
				isWaitingForChoice = true
				NpcCommons.ContextChoices(own, choices)
		else:
			if step + 1 < steps.size():
				NpcCommons.ContextContinue(own)
			else:
				NpcCommons.ContextClose(own)
	else:
		ToggleWindow(false)

	if IsDone():
		ToggleWindow(false)
		own.ClearScript()

func IsDone() -> bool:
	return own != npc and step >= steps.size() and not IsWaiting()

func IsWaiting() -> bool:
	return own == npc or isWaitingForChoice or timerCount > 0

# Default functions
func _init(_npc : NpcAgent, _own : BaseAgent):
	assert(_npc != null and _own != null, "Trying to init a NPC Script with a missing player or NPC")
	own = _own
	npc = _npc
	OnStart()

func OnStart(): pass
func OnContinue(): pass
func OnTrigger(): pass
