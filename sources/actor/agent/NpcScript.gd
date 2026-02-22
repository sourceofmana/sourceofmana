extends RefCounted
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
	else:
		CallGlobal("OnQuit")
		return false

func IsTriggering() -> bool:
	return ActorCommons.IsTriggering(npc)

# Monster
func Spawn(mobID : int, count : int = 1, position : Vector2 = Vector2.ZERO, spawnRadius : Vector2 = Vector2(64, 64)) -> Array[MonsterAgent]:
	return NpcCommons.Spawn(npc, mobID, count, position, spawnRadius)

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
func Warp(mapID : int, position : Vector2):
	if not IsPlayer(): return
	Action(NpcCommons.Warp.bind(own, mapID, position))

# Quest
func SetQuest(questID : int, state : int):
	if not IsPlayer(): return
	Action(NpcCommons.SetQuest.bind(own, questID, state))

func GetQuest(questID : int) -> int:
	if not IsPlayer(): return ProgressCommons.UnknownProgress
	return own.progress.GetQuest(questID)

func IsQuestStarted(questID : int) -> bool:
	return GetQuest(questID) != ProgressCommons.UnknownProgress

func IsQuestCompleted(questID : int) -> bool:
	return GetQuest(questID) == ProgressCommons.CompletedProgress

# Display
func Notification(text : String):
	if not IsPlayer(): return
	NpcCommons.PushNotification(own, text)

# Dialogue
func Mes(mes : String):
	if not IsPlayer(): return
	steps.append({"text": mes})

func Choice(mes : String, callable : Callable = Callback.Empty):
	if not IsPlayer(): return
	if steps.is_empty():
		steps.append({"choices": []})

	var dialogueStep : Dictionary = steps[steps.size() - 1]
	if not dialogueStep.has("choices"):
		dialogueStep["choices"] = []

	dialogueStep["choices"].append({"text": mes, "action": callable})

func Action(callable : Callable):
	if not IsPlayer(): return
	steps.append({"action": callable})

func Chat(mes : String):
	if not IsPlayer(): return
	NpcCommons.Chat(npc, own, mes)

func Greeting():
	if not IsPlayer(): return
	NpcCommons.Chat(npc, own, NpcCommons.GetRandomGreeting(own.nick))

func Farewell():
	if not IsPlayer(): return
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
		Close()

func ClearTimer(timer : Timer):
	if timer and not timer.is_stopped() and not timer.is_queued_for_deletion():
		timer.stop()
		timer.queue_free()
		timerCount -= 1
		if own and IsDone():
			Close()

# Inventory
func HasItem(itemID : int, count : int = 1) -> bool:
	if not IsPlayer(): return false
	var cell : ItemCell = DB.GetItem(itemID)
	return own.inventory.HasItem(cell, count) if cell else false

func HasItemsSpace(items : Array) -> bool:
	if not IsPlayer(): return false
	var totalCount : int = 0
	for item in items:
		var itemCount : int = 1
		var cell : ItemCell = null
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
	if not IsPlayer(): return false
	return own.inventory.HasSpace(itemCount)

func AddItem(itemID : int, count : int = 1, customfield : String = ""):
	if not IsPlayer(): return false
	Action(NpcCommons.AddItem.bind(own, itemID, count, customfield))

func RemoveItem(itemID : int, count : int = 1, customfield : String = ""):
	if not IsPlayer(): return false
	Action(NpcCommons.RemoveItem.bind(own, itemID, count, customfield))

# Karma
func AddKarma(value : int):
	if not IsPlayer(): return
	Action(NpcCommons.AddKarma.bind(own, value))

# Money & Experience
func AddExp(value : int):
	if not IsPlayer() or value <= 0: return
	Action(own.stat.AddExperience.bind(value))

func AddGP(value : int):
	if not IsPlayer() or value <= 0: return
	Action(own.stat.AddGP.bind(value))

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
	var stepCount : int = steps.size()
	if isWaitingForChoice:
		pass # Skip the current step if we are waiting for a player choice
	elif step < stepCount:
		var dialogueStep : Dictionary = steps[step]
		while dialogueStep.has("action"):
			dialogueStep["action"].call()
			if step + 1 < stepCount:
				step += 1
				dialogueStep = steps[step]
			else:
				break

		if dialogueStep.has("text"):
			if not windowToggled:
				ToggleWindow(true)

			NpcCommons.ContextText(own, npc.nick, dialogueStep["text"])

		if dialogueStep.has("choices"):
			if not windowToggled:
				ToggleWindow(true)

			var choices : PackedStringArray = []
			for choice in dialogueStep["choices"]:
				if choice.has("text"):
					choices.append(choice["text"])
			if choices.size() > 0:
				isWaitingForChoice = true
				NpcCommons.ContextChoices(own, choices)
		else:
			if step + 1 < stepCount:
				NpcCommons.ContextContinue(own)
			else:
				NpcCommons.ContextClose(own)
	else:
		ToggleWindow(false)

	if IsDone():
		Close()

func Close():
	if IsPlayer():
		ToggleWindow(false)
	own.ClearScript()

func IsDone() -> bool:
	return own != npc and step >= steps.size() and not IsWaiting()

func IsWaiting() -> bool:
	return own == npc or isWaitingForChoice or timerCount > 0

func IsPlayer() -> bool:
	return own is PlayerAgent

# Default functions
func _init(_npc : NpcAgent, _own : BaseAgent):
	assert(_npc != null and _own != null, "Trying to init a NPC Script with a missing player or NPC")
	if _npc and _own:
		own = _own
		npc = _npc
		OnStart()
		if npc != own:
			npc.AddInteraction()
			if own.data._direction == ActorCommons.Direction.UNKNOWN:
				own.LookAt(npc)
			if npc.data._direction == ActorCommons.Direction.UNKNOWN:
				npc.LookAt(own)

func OnStart(): pass
func OnContinue(): pass
func OnTrigger(): pass
func OnQuit():
	if not IsPlayer():
		npc.SubInteraction()
