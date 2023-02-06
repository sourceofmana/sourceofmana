extends Node

#
func ConnectPlayer(playerName : String):
	if not Launcher.World.HasEntity(playerName):
		var player : PlayerEntity = Launcher.World.CreateEntity("Player", "Default Entity", playerName, true)
		var map : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
		var pos : Vector2	= Launcher.Conf.GetVector2("Default", "startPos", Launcher.Conf.Type.MAP)

		Launcher.World.Spawn(map, player)
		Launcher.Network.Client.GetPlayer(player, map, pos)

func SetDisconnectPlayer(playerName : String):
	Launcher.World.RemoveEntity(playerName)

#
func GetEntities(mapName : String, entityName : String):
	var entities : Array[BaseEntity] = Launcher.World.GetEntities(mapName, entityName)
	Launcher.Network.Client.SetEntities(entities)

func SetWarp(oldMapName : String, newMapName : String, entity):
	Launcher.World.Warp(oldMapName, newMapName, entity)

#
func ConnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer connected: %s" % id)

func DisconnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer disconnected: %s" % id)
