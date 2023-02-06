extends Node

#
func SetDisconnectPlayer():
	if Launcher.Player:
		if Launcher.Network.Server:
			Launcher.Network.Server.SetDisconnectPlayer(Launcher.Player.entityName)

func DisconnectPlayer():
	Launcher.FSM.EnterLogin()

func GetPlayer(entity : PlayerEntity, map : String, pos : Vector2i):
	Launcher.Player = entity
	Launcher.Util.Assert(Launcher.Player != null, "Player was not created")
	if Launcher.Player and Launcher.Map:
		Launcher.Map.WarpEntity(map, pos)

		if Launcher.Debug:
			Launcher.Debug.SetPlayerInventory()

		if Launcher.FSM:
			Launcher.FSM.emit_signal("enter_game")

func GetEntities(mapName : String):
	if Launcher.Network.Server:
		Launcher.Network.Server.GetEntities(mapName, Launcher.Player.entityName)

func SetEntities(entities : Array[BaseEntity]):
	for entity in entities:
		Launcher.Map.AddChild(entity)

func SetWarp(oldMapName : String, newMapName : String):
	if Launcher.Network.Server:
		Launcher.Network.Server.SetWarp(oldMapName, newMapName, Launcher.Player)
