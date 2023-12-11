extends CanvasModulate

#
func _enter_tree():
	visible = Effects.shadowEnabled
	Effects.shadowPool.push_back(self)

func _exit_tree():
	Effects.shadowPool.erase(self)
