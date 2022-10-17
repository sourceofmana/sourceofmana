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

	# Player
	Launcher.Entities.activePlayer = Launcher.Entities.Spawn("Default Entity", "Enora", true)

	# Other players
#	Launcher.Entities.otherPlayers.append(Launcher.Entities.Spawn("Default Entity", "Player"))

	# NPCs
	Launcher.Entities.npcs.append(Launcher.Entities.Spawn("Default Entity", "NPC"))
	Launcher.Entities.npcs.append(Launcher.Entities.Spawn("Default Entity", "NPC"))

	# Monsters
	Launcher.Entities.monsters.append(Launcher.Entities.Spawn("Phatyna"))

	# Warps
	Launcher.Map.Warp(null, map, playerPos, Launcher.Entities.activePlayer)
	for entity in Launcher.Entities.otherPlayers:
		Launcher.Map.Warp(null, map, playerPos + Vector2(1, 0), entity)
	for entity in Launcher.Entities.npcs:
		Launcher.Map.Warp(null, map, playerPos + Vector2(-1, 0), entity)
	for entity in Launcher.Entities.monsters:
		Launcher.Map.Warp(null, map, playerPos + Vector2(0, 2), entity)

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
				Launcher.Util.Assert(false, "Wanted FSM state not handled.")

		currentState = nextState

#
func _post_ready():
	if Launcher.Conf.GetBool("Default", "skipLogin", Launcher.Conf.Type.PROJECT):
		nextState = States.IN_GAME
	else:
		nextState = States.SERVER_SELECTION

	UpdateFSM()
