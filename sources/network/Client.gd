extends Node


var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= 0

#
func _init():
	var serverAdress : String	= Launcher.Conf.GetString("Network", "serverAdress", Launcher.Conf.Type.PROJECT)
	var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
	var maxPlayerCount : int	= Launcher.Conf.GetInt("Network", "maxPlayerCount", Launcher.Conf.Type.PROJECT)
	peer.create_client(serverAdress, serverPort, maxPlayerCount)

	Launcher.Root.multiplayer.multiplayer_peer = peer
	uniqueID = Launcher.Root.multiplayer.get_unique_id()
