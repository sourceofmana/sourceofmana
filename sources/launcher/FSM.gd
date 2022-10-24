extends Node

#
enum States { NONE = 0, LOGIN_CONNECTION, CHAR_SELECTION, IN_GAME }

#
var currentState	= States.LOGIN_CONNECTION
var nextState		= States.NONE

#
func Login():
	pass

func Char():
	pass

func Game():
	if Launcher.World:
		var map : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
		var pos : Vector2	= Launcher.Conf.GetVector2("Default", "startPos", Launcher.Conf.Type.MAP)
		Launcher.Entities.playerEntity = Launcher.World.CreateEntity("Default Entity", "Enora", true)
		Launcher.Entities.playerEntity.isPlayableController = true
		Launcher.World.Spawn(map, Launcher.Entities.playerEntity)
		Launcher.Map.WarpEntity(map, pos, Launcher.Entities.playerEntity)

	if Launcher.Debug:
		Launcher.Debug.SetPlayerInventory(Launcher.Entities.playerEntity)

#
func UpdateFSM():
	if currentState != nextState:
		match nextState:
			States.LOGIN_CONNECTION:
				Login()
			States.CHAR_SELECTION:
				Char()
			States.IN_GAME:
				Game()
			_:
				Launcher.Util.Assert(false, "Wanted FSM state not handled.")

		currentState = nextState

#
func _post_ready():
	if Launcher.Conf.GetBool("Default", "skipLogin", Launcher.Conf.Type.PROJECT):
		nextState = States.IN_GAME
	else:
		nextState = States.SERVER_SELECTION

	UpdateFSM()
