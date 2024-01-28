extends BaseAgent
class_name MonsterAgent

#
static func GetEntityType() -> EntityCommons.Type: return EntityCommons.Type.MONSTER

#
func _specific_process():
	pass

func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Util.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	castTimer = Timer.new()
	castTimer.set_name("CastTimer")
	castTimer.set_one_shot(true)
	add_child.call_deferred(castTimer)

	super._ready()
