extends Object
class_name NpcScript

# Script variables
var npc : NpcAgent					= null
var pc : PlayerAgent				= null

var timer : Timer					= null
var steps : Array[Dictionary]		= []
var step : int						= 0
var isWaitingForChoice : bool		= false

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
	var newTimer : Timer = Callback.SelfDestructTimer(pc, 1.0, ClearTimer)
	if timer and timer.time_left < delay:
		timer = newTimer

func ClearTimer():
	timer = null

# Interaction logic
func InteractChoice(choiceId : int):
	var dialogueStep : Dictionary = steps[step]
	if choiceId < dialogueStep["choices"].size():
		var choice : Dictionary = dialogueStep["choices"][choiceId]
		if choice.has("action"):
			isWaitingForChoice = false
			step = 0
			steps.clear()
			choice["action"].call()
		ApplyStep()

func Interact():
	step += 1
	ApplyStep()

func ApplyStep():
	if step < steps.size():
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
	if IsDone():
		pc.ClearScript()

func IsDone() -> bool:
	return step + 1 >= steps.size() and not isWaitingForChoice and timer == null

# Default functions
func Init(_npc : NpcAgent, _pc : PlayerAgent) -> bool:
	if not _pc or not _npc:
		Util.Assert(false, "Trying to init a NPC Script with a missing player or NPC")
		return false
	pc = _pc
	npc = _npc
	OnDefault()
	return true

func OnDefault(): pass
