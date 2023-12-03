extends WindowPanel

#
func _ready():
	pass


func _on_visibility_changed():
	if Launcher.Action:
		Launcher.Action.Enable(not visible)
