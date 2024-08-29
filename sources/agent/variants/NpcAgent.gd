extends BaseAgent
class_name NpcAgent

#
var scriptPath : String				= ""
var scriptPreset : GDScript			= null

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.NPC

#
func Interact(player : Actor):
	if player is not PlayerAgent:
		return

	if not player.currentScript:
		player.AddScript(self)
	else:
		if player.currentScript.IsWaiting():
			return
		elif player.currentScript.npc == self:
			player.currentScript.step += 1
	if player.currentScript.npc == self:
		player.currentScript.ApplyStep()

#
func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Callback.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	if not scriptPath.is_empty():
		scriptPreset = FileSystem.LoadScript(scriptPath, false)

	super._ready()
