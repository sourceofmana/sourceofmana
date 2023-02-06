extends Node

#
var Client							= null
var Server							= null

#
var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= 0

#
func ConnectMode():
	if uniqueID != 0:
		pass

	if Client and Server:
		ConnectPlayer(Launcher.FSM.playerName)
	elif Client:
		var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
		var serverAdress : String	= Launcher.Conf.GetString("Network", "serverAdress", Launcher.Conf.Type.PROJECT)

		var ret = peer.create_client(serverAdress, serverPort)
		Launcher.Util.Assert(ret == OK, "Client could not connect, please check the server adress %s and port number %d" % [serverAdress, serverPort])
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			Launcher.Root.multiplayer.connected_to_server.connect(ConnectPlayer.bind(Launcher.FSM.playerName))
			Launcher.Root.multiplayer.connection_failed.connect(DisconnectPlayer.bind(Launcher.FSM.playerName))
			Launcher.Root.multiplayer.server_disconnected.connect(DisconnectPlayer.bind(Launcher.FSM.playerName))

			uniqueID = Launcher.Root.multiplayer.get_unique_id()
	elif Server:
		var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
		var maxPlayerCount : int	= Launcher.Conf.GetInt("Network", "maxPlayerCount", Launcher.Conf.Type.PROJECT)
		var ret = peer.create_server(serverPort, maxPlayerCount)

		Launcher.Util.Assert(ret == OK, "Server could not be created, please check if your port %d is valid" % serverPort)
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			Launcher.Root.multiplayer.peer_connected.connect(Server.ConnectPeer)
			Launcher.Root.multiplayer.peer_disconnected.connect(Server.DisconnectPeer)
			Launcher.Util.PrintLog("[Server] Initialized on port %d" % serverPort)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()

@rpc(any_peer)
func ConnectPlayer(playerName : String):
	if Client:		ServerCall("ConnectPlayer", [playerName])
	elif Server:	Server.ConnectPlayer(playerName)

@rpc(any_peer)
func DisconnectPlayer(playerName : String):
	if Client:		ServerCall("DisconnectPlayer", [playerName])
	elif Server:	Server.DisconnectPlayer(playerName)

#
func ServerCall(methodName : String, args : Array):
	if Server:
		Server.callv(methodName, args)
	else:
		callv("rpc", [methodName] + args)

func ClientCall(methodName : String, args : Array):
	if Client:
		Client.callv(methodName, args)
	else:
		callv("rpc", [methodName] + args)

func NetMode(isClient : bool, isServer : bool):
	if isClient:
		Client = Launcher.FileSystem.LoadSource("network/Client.gd")
	if isServer:
		Server = Launcher.FileSystem.LoadSource("network/Server.gd")
