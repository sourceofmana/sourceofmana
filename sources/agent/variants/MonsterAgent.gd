extends BaseAgent
class_name MonsterAgent

#
func _specific_process():
	var parent : Node = get_parent()
	if parent != null and parent is WorldService.Instance:
		AI.Update(self, parent.map)
