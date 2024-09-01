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

	if not player.ownScript:
		player.AddScript(self)
	else:
		if player.ownScript.IsWaiting():
			player.ownScript.OnContinue()
		elif player.ownScript.npc == self:
			player.ownScript.step += 1
	if player.ownScript.npc == self:
		player.ownScript.ApplyStep()

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
