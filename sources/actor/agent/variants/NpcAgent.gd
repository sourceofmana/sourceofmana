extends AIAgent
class_name NpcAgent

#
var playerScriptPath : String				= ""
var playerScriptPreset : GDScript			= null
var ownScriptPath : String					= ""
var ownScript : NpcScript					= null
var interactionCount : int					= 0

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.NPC

#
func Interact(player : Actor):
	if player is not PlayerAgent or not ActorCommons.IsAlive(player):
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

func AddInteraction():
	if interactionCount == 0:
		AI.Stop(self)
	interactionCount = interactionCount + 1

func SubInteraction():
	if interactionCount > 0:
		interactionCount = interactionCount - 1
	if interactionCount == 0:
		AI.Reset(self)

#
func _ready():
	if not playerScriptPath.is_empty():
		playerScriptPreset = FileSystem.LoadScript(playerScriptPath, false)
	if not ownScriptPath.is_empty():
		ownScript = FileSystem.LoadScript(ownScriptPath, false).new(self, self)

	super._ready()
