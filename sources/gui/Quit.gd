@tool
extends WindowPanel

@onready var stayButton : Button	= $Margin/VBoxContainer/Container/ButtonChoice/Stay
@onready var logOutButton : Button	= $Margin/VBoxContainer/Container/ButtonChoice/LogOut
@onready var quitButton : Button	= $Margin/VBoxContainer/Container/ButtonChoice/Quit

#
func EnableControl(state : bool):
	super(state)
	if state:
		logOutButton.set_visible(FSM.IsGameState())
		stayButton.grab_focus()

#
func _on_logout_pressed():
	FSM.EnterState(FSM.States.LOGIN_SCREEN)
	Network.DisconnectAccount()
	EnableControl(false)

func _on_quit_pressed():
	FSM.EnterState(FSM.States.QUIT)
	ToggleControl()

func _on_stay_pressed():
	ToggleControl()
