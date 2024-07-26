extends ServiceBase

#
signal enter_login
signal exit_login
signal enter_char_selection
signal exit_char_selection
signal enter_game
signal exit_game

#
enum States { NONE = 0, LOGIN_CONNECTION, CHAR_SELECTION, IN_GAME, QUIT }
enum Phases { ENTER = 0, UPDATE, EXIT }

#
var playerName : String				= ""

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
					enter_login.emit()
				Phases.EXIT:
					exit_login.emit()
		States.CHAR_SELECTION:
			match GetPhase():
				Phases.ENTER:
					enter_char_selection.emit()
				Phases.EXIT:
					exit_char_selection.emit()
		States.IN_GAME:
			match GetPhase():
				Phases.ENTER:
					enter_game.emit()
				Phases.UPDATE:
					pass
				Phases.EXIT:
					exit_game.emit()
		States.QUIT:
			Launcher._quit()

#
func _physics_process(_delta):
	UpdateStates()
	lastState		= currentState
	currentState	= nextState

func _post_launch():
	EnterState(States.LOGIN_CONNECTION)

	isInitialized = true
