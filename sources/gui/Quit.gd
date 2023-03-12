extends WindowPanel

@onready var leaveButton : Button	= $VBoxContainer/ButtonChoice/Leave

#
func _on_leave_pressed():
	Launcher._quit()

func _on_stay_pressed():
	ToggleControl()

func _on_window_draw():
	if leaveButton:
		leaveButton.grab_focus()
