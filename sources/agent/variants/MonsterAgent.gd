extends BaseAgent
class_name MonsterAgent

#
static func GetEntityType() -> EntityCommons.Type: return EntityCommons.Type.MONSTER

#
func _specific_process():
	var parent : Node = get_parent()
	if parent != null and parent is WorldInstance:
		AI.Update(self, parent.map)

func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	add_child.call_deferred(aiTimer)

	castTimer = Timer.new()
	castTimer.set_name("CastTimer")
	castTimer.set_one_shot(true)
	add_child.call_deferred(castTimer)
