extends Node


var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= 0

#
func SetConnectPlayer(playerName : String):
	var serverAdress : String	= Launcher.Conf.GetString("Network", "serverAdress", Launcher.Conf.Type.PROJECT)
	var serverPort : int		= Launcher.Conf.GetInt("Network", "serverPort", Launcher.Conf.Type.PROJECT)
	var maxPlayerCount : int	= Launcher.Conf.GetInt("Network", "maxPlayerCount", Launcher.Conf.Type.PROJECT)
	peer.create_client(serverAdress, serverPort, maxPlayerCount)

	Launcher.Root.multiplayer.multiplayer_peer = peer
	uniqueID = Launcher.Root.multiplayer.get_unique_id()

	Launcher.Server.SetConnectPlayer(playerName)

func SetDisconnectPlayer():
	if Launcher.Player:
		Launcher.Server.SetDisconnectPlayer(Launcher.Player.entityName)

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
	Launcher.Server.GetEntities(mapName, Launcher.Player.entityName)

func SetEntities(entities : Array[BaseEntity]):
	for entity in entities:
		Launcher.Map.AddChild(entity)

func SetWarp(oldMapName : String, newMapName : String):
	Launcher.Server.SetWarp(oldMapName, newMapName, Launcher.Player)
