extends Node

#
signal enter_login
signal enter_char_selection
signal enter_game

#
enum States { NONE = 0, LOGIN_CONNECTION, CHAR_SELECTION, IN_GAME }

#
var playerName		= ""
var currentState	= States.NONE
var nextState		= States.LOGIN_CONNECTION

#
func EnterLogin():
	emit_signal("enter_login")

func ExitLogin(loginName : String):
	playerName = loginName
	nextState = States.CHAR_SELECTION

func EnterCharSelection():
	nextState = States.IN_GAME
	emit_signal("enter_char_selection")

func EnterGame():
	if Launcher.World:
		var map : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
		var pos : Vector2	= Launcher.Conf.GetVector2("Default", "startPos", Launcher.Conf.Type.MAP)
		Launcher.Player		= Launcher.World.CreateEntity("Player", "Default Entity", playerName, true)

		Launcher.Util.Assert(Launcher.Player != null, "Player was not created")
		if Launcher.Player:
			Launcher.World.Spawn(map, Launcher.Player)
			Launcher.Map.WarpEntity(map, pos)

			if Launcher.Debug:
				Launcher.Debug.SetPlayerInventory()

			emit_signal("enter_game")

#
func _process(_delta):
	if currentState != nextState:
		currentState = nextState
		match nextState:
			States.LOGIN_CONNECTION:
				EnterLogin()
			States.CHAR_SELECTION:
				EnterCharSelection()
			States.IN_GAME:
				EnterGame()
			_:
				Launcher.Util.Assert(false, "Wanted FSM state not handled.")

#
func _post_ready():
	if Launcher.Conf.GetBool("Default", "skipLogin", Launcher.Conf.Type.PROJECT):
		nextState = States.IN_GAME
	else:
		nextState = States.LOGIN_CONNECTION
