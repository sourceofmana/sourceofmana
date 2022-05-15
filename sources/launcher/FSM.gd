extends Node

#
enum States { SERVER_SELECTION = 0, LOGIN_CONNECTION, CHAR_SELECTION, IN_GAME }

#
var state = States.SERVER_SELECTION

#
func Server():
	pass

func Char():
	pass

func Login():
	var map : String = Launcher.Conf.Map.get_value("Default", "startMap")
	var playerPos : Vector2 = Launcher.Conf.Map.get_value("Default", "startPos")

	if Launcher.Save:
		map = Launcher.Save.GetMap()
		playerPos = Launcher.Save.GetPlayerPos()

	Launcher.Map.Warp(null, map, playerPos)


