extends WindowPanel

@onready var stayButton : Button	= $Margin/VBoxContainer/Container/ButtonChoice/Stay
@onready var logOutButton : Button	= $Margin/VBoxContainer/Container/ButtonChoice/LogOut
@onready var quitButton : Button	= $Margin/VBoxContainer/Container/ButtonChoice/Quit

#
func EnableControl(state : bool):
	super(state)
	if state:
		Center()
		if FSM.IsGameState():
			logOutButton.set_visible(true)
			logOutButton.grab_focus()
		else:
			if quitButton.is_visible():
				logOutButton.set_visible(false)
				quitButton.grab_focus()
			else:
				set_visible(false)

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

func _ready():
	if LauncherCommons.isWeb:
		quitButton.set_visible(false)
