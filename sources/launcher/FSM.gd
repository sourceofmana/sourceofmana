extends Node

#
signal enter_login
signal enter_char_selection
signal enter_game

#
enum States { NONE = 0, LOGIN_CONNECTION, CHAR_SELECTION, IN_GAME, QUIT }
enum Phases { ENTER = 0, UPDATE, EXIT }

#
var playerName						= ""

var lastState : States				= States.NONE
var currentState : States			= States.NONE
var nextState : States				= States.NONE

#
func GetPhase() -> Phases:
	if lastState != currentState:
		return Phases.ENTER
	elif currentState != nextState:
		return Phases.EXIT
	return Phases.UPDATE

func EnterState(state : States):
	nextState = state

#
func UpdateStates():
	match currentState:
		States.LOGIN_CONNECTION:
			match GetPhase():
				Phases.ENTER:
					emit_signal("enter_login")
				Phases.EXIT:
					playerName = Launcher.GUI.loginWindow.nameTextControl.get_text()
		States.CHAR_SELECTION:
			match GetPhase():
				Phases.ENTER:
					emit_signal("enter_char_selection")
					EnterState(States.IN_GAME) # Skip char selection
		States.IN_GAME:
			match GetPhase():
				Phases.ENTER:
					Launcher.Network.NetCreate()
				Phases.UPDATE:
					pass
				Phases.EXIT:
					Launcher.Network.NetDestroy()
		States.QUIT:
			Launcher._quit()

#
func _physics_process(_delta):
	UpdateStates()
	lastState		= currentState
	currentState	= nextState

func _post_launch():
	EnterState(States.LOGIN_CONNECTION)
