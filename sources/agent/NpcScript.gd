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

# Display
func Trigger() -> bool:
	return npc.SetState(ActorCommons.State.TRIGGER) if npc else false

# Dialogue
func Mes(mes : String):
	steps.append({"text": mes})

func Choice(mes : String, callable : Callable):
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
func AddTimer(caller : BaseAgent, delay : float, callback : Callable):
	if caller:
		var newTimer : Timer = Callback.SelfDestructTimer(caller, delay, TimeOut.bind(callback))
		if newTimer:
			timerCount += 1
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
		var cell : BaseCell = DB.ItemsDB[itemID] if DB.ItemsDB.has(itemID) else null
		return own.inventory.HasItem(cell, count) if cell else false
	return false

func AddItem(itemID : int, count : int = 1) -> bool:
	if own is PlayerAgent:
		var cell : BaseCell = DB.ItemsDB[itemID] if DB.ItemsDB.has(itemID) else null
		return own.inventory.AddItem(cell, count) if cell else false
	return false

func RemoveItem(itemID : int, count : int = 1) -> bool:
	if own is PlayerAgent:
		var cell : BaseCell = DB.ItemsDB[itemID] if DB.ItemsDB.has(itemID) else null
		return own.inventory.RemoveItem(cell, count) if cell else false
	return false

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
		NpcCommons.ContextText(own, own.nick, dialogueStep["text"])
		var choice : Dictionary = dialogueStep["choices"][choiceId]
		if choice.has("action"):
			isWaitingForChoice = false
			step = 0
			steps.clear()
			choice["action"].call()

		ApplyStep()

func ApplyStep():
	if step < steps.size():
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
	Util.Assert(_npc != null and _own != null, "Trying to init a NPC Script with a missing player or NPC")
	own = _own
	npc = _npc
	OnStart()

func OnStart(): pass
func OnContinue(): pass
