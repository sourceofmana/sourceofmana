extends Node


var peer = ENetMultiplayerPeer.new()

#
@rpc(any_peer)
func SetConnectPlayer(playerName : String):
	if not Launcher.World.HasEntity(playerName):
		var player : PlayerEntity = Launcher.World.CreateEntity("Player", "Default Entity", playerName, true)
		var map : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
		var pos : Vector2	= Launcher.Conf.GetVector2("Default", "startPos", Launcher.Conf.Type.MAP)

		Launcher.World.Spawn(map, player)
		Launcher.Client.GetPlayer(player, map, pos)

@rpc(any_peer)
func SetDisconnectPlayer(playerName : String):
	Launcher.World.RemoveEntity(playerName)

@rpc(any_peer)
func GetEntities(mapName : String, entityName : String):
	var entities : Array[BaseEntity] = Launcher.World.GetEntities(mapName, entityName)
	Launcher.Client.SetEntities(entities)

@rpc(any_peer)
func SetWarp(oldMapName : String, newMapName : String, entity):
	Launcher.World.Warp(oldMapName, newMapName, entity)

#
func player_connected(id : int):
	Launcher.Util.PrintLog("[Server] Peer connected: %s" % id)

func player_disconnected(id : int):
	Launcher.Util.PrintLog("[Server] Peer disconnected: %s" % id)

#
func _init():
	if not Launcher.Client:
		var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
		var maxPlayerCount : int	= Launcher.Conf.GetInt("Network", "maxPlayerCount", Launcher.Conf.Type.PROJECT)
		var ret = peer.create_server(serverPort, maxPlayerCount)

		Launcher.Util.Assert(ret == OK, "Server could not be created, please check if your port %d is valid" % serverPort)
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			Launcher.Root.multiplayer.peer_connected.connect(player_connected)
			Launcher.Root.multiplayer.peer_disconnected.connect(player_disconnected)
			Launcher.Util.PrintLog("[Server] Initialized on port %d" % serverPort)
