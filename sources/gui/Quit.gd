extends VBoxContainer

@onready var leaveButton : Button = $ButtonChoice/Leave

#
func _on_Leave_pressed():
	get_tree().quit()

func _on_Stay_pressed():
	get_parent().set_visible(false)

func _on_window_draw():
	if leaveButton:
		leaveButton.grab_focus()
