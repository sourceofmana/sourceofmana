extends AIAgent
class_name NpcAgent

#
var playerScriptPath : String				= ""
var playerScriptPreset : GDScript			= null
var ownScriptPath : String					= ""
var ownScript : NpcScript					= null
var interactionCount : int					= 0

#
static func GetActorType() -> ActorCommons.Type: return ActorCommons.Type.NPC

#
func Interact(player : Actor):
	if player is not PlayerAgent:
		return

	if not player.ownScript:
		if SkillCommons.IsTargetable(player, self):
			player.AddScript(self)
	else:
		if player.ownScript.IsWaiting():
			player.ownScript.OnContinue()
		elif player.ownScript.npc == self:
			player.ownScript.step += 1

	if player.ownScript and player.ownScript.npc == self:
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

func AddTrigger():
	var triggerObject : TriggerObject = TriggerObject.new()
	triggerObject.linkedNpc = self

	if spawnInfo.trigger_radius > 0.0:
		# Use explicit trigger radius
		var collisionShape : CollisionShape2D = CollisionShape2D.new()
		var circle : CircleShape2D = CircleShape2D.new()
		circle.radius = spawnInfo.trigger_radius
		collisionShape.shape = circle
		triggerObject.add_child(collisionShape)
	elif spawnInfo.spawn_offset != Vector2i.ZERO:
		# Use spawn rectangle area
		var collisionShape : CollisionShape2D = CollisionShape2D.new()
		var rect : RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(spawnInfo.spawn_offset * 2)
		collisionShape.shape = rect
		triggerObject.add_child(collisionShape)
	elif data and data._radius > 0:
		# Fall back to entity radius
		var collisionShape : CollisionShape2D = CollisionShape2D.new()
		var circle : CircleShape2D = CircleShape2D.new()
		circle.radius = float(data._radius)
		collisionShape.shape = circle
		triggerObject.add_child(collisionShape)
	else:
		triggerObject.free()
		return

	add_child.call_deferred(triggerObject)

#
func _ready():
	if not playerScriptPath.is_empty():
		playerScriptPreset = FileSystem.LoadScript(playerScriptPath, false)
	if not ownScriptPath.is_empty():
		ownScript = FileSystem.LoadScript(ownScriptPath, false).new(self, self)

	if spawnInfo and spawnInfo.has_trigger:
		AddTrigger()

	super._ready()
