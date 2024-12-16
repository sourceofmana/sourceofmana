extends Node

#
signal enter_login
signal exit_login
signal enter_login_progress
signal exit_login_progress
signal enter_char
signal exit_char
signal enter_char_progress
signal exit_char_progress
signal enter_game
signal exit_game

#
enum States { NONE = 0, LOGIN_SCREEN, LOGIN_PROGRESS, CHAR_SCREEN, CHAR_PROGRESS, IN_GAME, QUIT }
enum Phases { ENTER = 0, UPDATE, EXIT }

#
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

func IsLoginState() -> bool:
	return currentState == States.LOGIN_SCREEN or currentState == States.LOGIN_PROGRESS

func IsCharacterState() -> bool:
	return currentState == States.CHAR_SCREEN or currentState == States.CHAR_PROGRESS

func IsGameState() -> bool:
	return currentState == States.IN_GAME

func EnterState(state : States):
	Util.PrintLog("Launcher", "Entering new FSM state: %s" % str(States.keys()[state]))
	nextState = state
	UpdateStates.call_deferred()

#
func UpdateStates():
	match currentState:
		States.LOGIN_SCREEN:
			match GetPhase():
				Phases.ENTER:
					enter_login.emit()
				Phases.EXIT:
					exit_login.emit()
		States.LOGIN_PROGRESS:
			match GetPhase():
				Phases.ENTER:
					enter_login_progress.emit()
				Phases.EXIT:
					exit_login_progress.emit()
		States.CHAR_SCREEN:
			match GetPhase():
				Phases.ENTER:
					enter_char.emit()
				Phases.EXIT:
					exit_char.emit()
		States.CHAR_PROGRESS:
			match GetPhase():
				Phases.ENTER:
					enter_char_progress.emit()
				Phases.EXIT:
					exit_char_progress.emit()
		States.IN_GAME:
			match GetPhase():
				Phases.ENTER:
					enter_game.emit()
				Phases.EXIT:
					exit_game.emit()
		States.QUIT:
			Launcher._quit()
			return

	lastState		= currentState
	currentState	= nextState
	if lastState != currentState or currentState != nextState:
		UpdateStates.call_deferred()
