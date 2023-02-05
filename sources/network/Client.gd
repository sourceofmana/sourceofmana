extends Node


var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= 0

#
func SetConnectPlayer(playerName : String):
	var serverAdress : String	= Launcher.Conf.GetString("Network", "serverAdress", Launcher.Conf.Type.PROJECT)
	var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
	var maxPlayerCount : int	= Launcher.Conf.GetInt("Network", "maxPlayerCount", Launcher.Conf.Type.PROJECT)
	peer.create_client(serverAdress, serverPort, maxPlayerCount)

	if Launcher.Server:
		ConnectPlayer(playerName)
	else:
		Launcher.Root.multiplayer.multiplayer_peer = peer
		Launcher.Root.multiplayer.connected_to_server.connect(ConnectPlayer.bind(playerName))
		Launcher.Root.multiplayer.connection_failed.connect(DisconnectPlayer)
		Launcher.Root.multiplayer.server_disconnected.connect(DisconnectPlayer)
		uniqueID = Launcher.Root.multiplayer.get_unique_id()

func ConnectPlayer(playerName):
	if Launcher.Server:
		Launcher.Server.SetConnectPlayer(playerName)

func SetDisconnectPlayer():
	if Launcher.Player:
		if Launcher.Server:
			Launcher.Server.SetDisconnectPlayer(Launcher.Player.entityName)

func DisconnectPlayer():
	Launcher.FSM.EnterLogin()

func GetPlayer(entity : PlayerEntity, map : String, pos : Vector2i):
	Launcher.Player = entity
	Launcher.Util.Assert(Launcher.Player != null, "Player was not created")
	if Launcher.Player:
		Launcher.Map.WarpEntity(map, pos)

		if Launcher.Debug:
			Launcher.Debug.SetPlayerInventory()

		if Launcher.FSM:
			Launcher.FSM.emit_signal("enter_game")

func GetEntities(mapName : String):
	if Launcher.Server:
		Launcher.Server.GetEntities(mapName, Launcher.Player.entityName)

func SetEntities(entities : Array[BaseEntity]):
	for entity in entities:
		Launcher.Map.AddChild(entity)

func SetWarp(oldMapName : String, newMapName : String):
	if Launcher.Server:
		Launcher.Server.SetWarp(oldMapName, newMapName, Launcher.Player)
