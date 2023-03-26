extends WindowPanel

@onready var leaveButton : Button	= $VBoxContainer/ButtonChoice/Leave

#
func _on_leave_pressed():
	if Launcher.Player:
		Launcher.FSM.EnterState(Launcher.FSM.States.LOGIN_CONNECTION)
	else:
		Launcher.FSM.EnterState(Launcher.FSM.States.QUIT)

func _on_stay_pressed():
	ToggleControl()

func _on_window_draw():
	if leaveButton:
		leaveButton.grab_focus()
