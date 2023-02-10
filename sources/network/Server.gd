extends Node

var playerMap : Dictionary = {}

#
func ConnectPlayer(playerName : String, rpcID : int = -1):
	if not playerMap.has(rpcID):

		if not Launcher.World.HasEntity(playerName):
			var player : PlayerEntity = Launcher.DB.Instantiate.CreateEntity("Player", "Default Entity", playerName)
			var map : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
			player.set_position(Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP))

			playerMap[rpcID] = playerName
			Launcher.World.Spawn(map, player)
			Launcher.Network.SetPlayerInWorld(map, rpcID)

func DisconnectPlayer(playerName : String, rpcID : int = -1):
	if playerMap.has(rpcID):
		playerMap.erase(rpcID)
		Launcher.World.RemoveEntity(playerName)

#
func GetEntities(mapName : String, entityName : String):
	var entities : Array[BaseEntity] = Launcher.World.GetEntities(mapName, entityName)
	Launcher.Network.Client.SetEntities(entities)

func SetWarp(oldMapName : String, newMapName : String, newPos : Vector2i, entity : BaseEntity):
	Launcher.World.Warp(oldMapName, newMapName, newPos, entity)

#
func ConnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer connected: %s" % id)

func DisconnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer disconnected: %s" % id)
