extends Node


var peer = ENetMultiplayerPeer.new()

func player_connected(id : int):
	Launcher.Util.PrintLog("Player connected: %s" % id)

func player_disconnected(id : int):
	Launcher.Util.PrintLog("Player disconnected: %s" % id)

#
func _init():
	var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
	var maxPlayerCount : int	= Launcher.Conf.GetInt("Network", "maxPlayerCount", Launcher.Conf.Type.PROJECT)
	var ret = peer.create_server(serverPort, maxPlayerCount)

	Launcher.Util.Assert(ret == OK, "Server could not be created, please check if your port %d is valid" % serverPort)
	if ret == OK:
		Launcher.Root.multiplayer.multiplayer_peer = peer
		Launcher.Root.multiplayer.peer_connected.connect(player_connected)
		Launcher.Root.multiplayer.peer_disconnected.connect(player_disconnected)
		Launcher.Util.PrintLog("Server created on port %d" % serverPort)
