extends BaseAgent
class_name NpcAgent

#
var scriptPath : String				= ""

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.NPC

#
func Interact(player : Actor):
	if player is not PlayerAgent:
		return

	if not player.currentScript:
		player.AddScript(self)
	elif player.currentScript and player.currentScript.npc == self:
		player.currentScript.step += 1
	if player.currentScript.npc == self:
		player.currentScript.ApplyStep()

#
func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Callback.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	super._ready()
