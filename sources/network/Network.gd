extends Node

#
var Client							= null
var Server							= null

#
var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= 0

#
@rpc(any_peer)
func ConnectPlayer(playerName : String, rpcID : int = -1):
	if Client:		NetCallServer("ConnectPlayer", [playerName])
	elif Server:	Server.ConnectPlayer(playerName, rpcID)

@rpc(any_peer)
func DisconnectPlayer(playerName : String, rpcID : int = -1):
	if Client:		NetCallServer("DisconnectPlayer", [playerName])
	elif Server:	Server.DisconnectPlayer(playerName, rpcID)

@rpc
func SetPlayerInWorld(mapName : String, rpcID : int = -1):
	if Server:		NetCallClient("SetPlayerInWorld", [mapName], rpcID)
	elif Client:	Client.SetPlayerInWorld(mapName)

@rpc(any_peer)
func GetAgents(rpcID : int = -1):
	if Client:		NetCallServer("GetAgents", [])
	elif Server:	Server.GetAgents(rpcID)

@rpc
func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityPos : Vector2i, rpcID : int = -1):
	if Server:		NetCallClient("AddEntity", [agentID, entityType, entityID, entityName, entityPos], rpcID)
	elif Client:	Client.AddEntity(agentID, entityType, entityID, entityName, entityPos)

@rpc(unreliable_ordered)
func UpdateEntity(agentID : int, velocity : Vector2, position : Vector2, rpcID : int = -1):
	if Server:		NetCallClient("UpdateEntity", [agentID, velocity, position], rpcID)
	elif Client:	Client.UpdateEntity(agentID, velocity, position)

#
func NetCallServer(methodName : String, args : Array):
	if Server:
		Server.callv(methodName, args)
	else:
		callv("rpc_id", [1, methodName] + args + [uniqueID])

func NetCallClient(methodName : String, args : Array, rpcID : int):
	if Client:
		Client.callv(methodName, args)
	else:
		callv("rpc_id", [rpcID, methodName] + args)

func NetCallClientGlobal(methodName : String, args : Array):
	if Client:
		Client.callv(methodName, args)
	else:
		callv("rpc", [methodName] + args)

func NetMode(isClient : bool, isServer : bool):
	if isClient:
		Client = Launcher.FileSystem.LoadSource("network/Client.gd")
	if isServer:
		Server = Launcher.FileSystem.LoadSource("network/Server.gd")

func NetCreate():
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
			var connectedCallback : Callable = ConnectPlayer.bind(Launcher.FSM.playerName) 
			if not Launcher.Root.multiplayer.connected_to_server.is_connected(connectedCallback):
				Launcher.Root.multiplayer.connected_to_server.connect(connectedCallback)
			if not Launcher.Root.multiplayer.connection_failed.is_connected(Client.Disconnect):
				Launcher.Root.multiplayer.connection_failed.connect(Client.Disconnect)
			if not Launcher.Root.multiplayer.server_disconnected.is_connected(Client.Disconnect):
				Launcher.Root.multiplayer.server_disconnected.connect(Client.Disconnect)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()
	elif Server:
		var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
		var maxPlayerCount : int	= Launcher.Conf.GetInt("Network", "maxPlayerCount", Launcher.Conf.Type.PROJECT)
		var ret = peer.create_server(serverPort, maxPlayerCount)

		Launcher.Util.Assert(ret == OK, "Server could not be created, please check if your port %d is valid" % serverPort)
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			if not Launcher.Root.multiplayer.peer_connected.is_connected(Server.ConnectPeer):
				Launcher.Root.multiplayer.peer_connected.connect(Server.ConnectPeer)
			if not Launcher.Root.multiplayer.peer_disconnected.is_connected(Server.DisconnectPeer):
				Launcher.Root.multiplayer.peer_disconnected.connect(Server.DisconnectPeer)
			Launcher.Util.PrintLog("[Server] Initialized on port %d" % serverPort)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()

func NetDestroy():
	uniqueID = 0
	if Client:
		Client.Disconnect()
