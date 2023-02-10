extends Node

#
func Disconnect():
	Launcher.FSM.EnterLogin()

func SetPlayerInWorld(map : String, _rpcID : int = -1):
	if Launcher.Map:
		Launcher.Map.ReplaceMapNode(map)

		if Launcher.Debug:
			Launcher.Debug.SetPlayerInventory()

		if Launcher.FSM:
			Launcher.FSM.emit_signal("enter_game")

func GetEntities(mapName : String):
	if Launcher.Network.Server:
		Launcher.Network.Server.GetEntities(mapName, Launcher.FSM.playerName)

func SetEntities(entities : Array[BaseEntity]):
	Launcher.Map.WarpEntities(entities)

func SetWarp(oldMapName : String, newMapName : String, newPos : Vector2i):
	if Launcher.Network.Server:
		Launcher.Network.Server.SetWarp(oldMapName, newMapName, newPos, Launcher.Player)
