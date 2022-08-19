extends Node

#
enum States { NONE = 0, SERVER_SELECTION, LOGIN_CONNECTION, CHAR_SELECTION, IN_GAME }

#
var currentState	= States.SERVER_SELECTION
var nextState		= States.NONE

#
func Server():
	pass

func Char():
	pass

func Login():
	pass

func Game():
	var map : String = Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
	var playerPos : Vector2 = Launcher.Conf.GetVector2("Default", "startPos", Launcher.Conf.Type.MAP)

	if Launcher.Save:
		map = Launcher.Save.GetMap()
		playerPos = Launcher.Save.GetPlayerPos()

	Launcher.Entities.activePlayer = Launcher.Entities.Spawn("Default Entity")
	Launcher.Map.Warp(null, map, playerPos, Launcher.Entities.activePlayer)

	if Launcher.Debug:
		Launcher.Debug.SetPlayerInventory(Launcher.Entities.activePlayer)

#
func UpdateFSM():
	if currentState != nextState:
		match nextState:
			States.SERVER_SELECTION:
				Server()
			States.LOGIN_CONNECTION:
				Login()
			States.CHAR_SELECTION:
				Char()
			States.IN_GAME:
				Game()
			_:
				assert(false, "Wanted FSM state not handled.")

		currentState = nextState

#
func _post_ready():
	if Launcher.Conf.GetBool("Default", "skipLogin", Launcher.Conf.Type.PROJECT):
		nextState = States.IN_GAME
	else:
		nextState = States.SERVER_SELECTION

	UpdateFSM()
