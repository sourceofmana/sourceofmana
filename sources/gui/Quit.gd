extends VBoxContainer

@onready var leaveButton : Button = $ButtonChoice/Leave

#
func _on_Leave_pressed():
	Launcher._quit()

func _on_Stay_pressed():
	Launcher.GUI.CloseCurrentWindow()

func _on_window_draw():
	if leaveButton:
		leaveButton.grab_focus()
