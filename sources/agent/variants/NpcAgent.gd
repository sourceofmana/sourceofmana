extends BaseAgent
class_name NpcAgent

#
var playerScriptPath : String				= ""
var playerScriptPreset : GDScript			= null
var ownScriptPath : String					= ""
var ownScript : NpcScript					= null

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
			player.currentScript.OnContinue()
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

	if not playerScriptPath.is_empty():
		playerScriptPreset = FileSystem.LoadScript(playerScriptPath, false)
	if not ownScriptPath.is_empty():
		ownScript = FileSystem.LoadScript(ownScriptPath, false).new(self, self)

	super._ready()
