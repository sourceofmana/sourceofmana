extends Object
class_name NpcScript

# Script variables
var npc : NpcAgent					= null
var pc : PlayerAgent				= null

var steps : Array[Dictionary]		= []
var step : int						= 0
var timerCount : int				= 0
var isWaitingForChoice : bool		= false
var windowToggled : bool			= false

# Display
func Trigger() -> bool:
	return npc.SetState(ActorCommons.State.TRIGGER) and npc.state == ActorCommons.State.TRIGGER if npc else false

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
	NpcCommons.Chat(npc, pc, mes)

func Greeting():
	NpcCommons.Chat(npc, pc, NpcCommons.GetRandomGreeting(pc.nick))

func Farewell():
	NpcCommons.Chat(npc, pc, NpcCommons.GetRandomFarewell(pc.nick))

# Timer
func AddTimer(delay : float):
	Callback.SelfDestructTimer(pc, delay, ClearTimer)
	timerCount += 1

func ClearTimer():
	timerCount -= 1
	if IsDone():
		pc.ClearScript()

# Interaction logic
func ToggleWindow(toggle : bool):
	if windowToggled != toggle:
		windowToggled = toggle
		NpcCommons.ToggleContext(pc, windowToggled)

func InteractChoice(choiceId : int):
	if not isWaitingForChoice:
		return

	var dialogueStep : Dictionary = steps[step]
	if choiceId < dialogueStep["choices"].size():
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
			NpcCommons.ContextText(npc, pc, dialogueStep["text"])

		if dialogueStep.has("choices"):
			var choices : PackedStringArray = []
			for choice in dialogueStep["choices"]:
				if choice.has("text"):
					choices.append(choice["text"])
			if choices.size() > 0:
				isWaitingForChoice = true
				NpcCommons.ContextChoices(pc, choices)
		else:
			if step + 1 < steps.size():
				NpcCommons.ContextContinue(pc)
			else:
				NpcCommons.ContextClose(pc)
	else:
		ToggleWindow(false)

	if IsDone():
		ToggleWindow(false)
		pc.ClearScript()

func IsDone() -> bool:
	return step >= steps.size() and not IsWaiting()

func IsWaiting() -> bool:
	return isWaitingForChoice or timerCount > 0

# Default functions
func _init(_npc : NpcAgent, _pc : PlayerAgent):
	if not _pc or not _npc:
		Util.Assert(false, "Trying to init a NPC Script with a missing player or NPC")
	pc = _pc
	npc = _npc
	OnDefault()

func OnDefault(): pass
