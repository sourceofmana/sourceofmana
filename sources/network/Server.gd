extends Node

var playerMap : Dictionary = {}

#
func ConnectPlayer(playerName : String, rpcID : int = -1):
	if not playerMap.has(rpcID):

		if not Launcher.World.HasAgent(playerName):
			var player : BaseAgent = Launcher.DB.Instantiate.CreateAgent("Player", "Default Entity", playerName)
			var map : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
			player.set_position(Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP))

			playerMap[rpcID] = player.get_rid().get_id()
			Launcher.World.rids[player.get_rid().get_id()] = player
			Launcher.World.Spawn(map, player)
			Launcher.Network.SetPlayerInWorld(map, rpcID)

func DisconnectPlayer(playerName : String, rpcID : int = -1):
	if playerMap.has(rpcID):
		playerMap.erase(rpcID)
		Launcher.World.RemoveEntity(playerName)

#
func GetAgents(mapName : String, entityName : String):
	var agents : Array[BaseAgent] = Launcher.World.GetAgents(mapName, entityName)
	Launcher.Network.Client.SetAgents(agents)

func UpdateEntity(_playerID : int, agentID : int, velocity : Vector2, position : Vector2):
	Launcher.Network.Client.UpdateEntity(agentID, velocity, position)

#
func SetWarp(entityName : String, oldMapName : String, newMapName : String, newPos : Vector2i):
	Launcher.World.Warp(entityName, oldMapName, newMapName, newPos)

func SetClickPos(pos : Vector2, senderRpcID : int = -1):
	if playerMap.has(senderRpcID):
		var playerAgentID : int = playerMap.get(senderRpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent:
			agent.WalkToward(pos)

func SetMovePos(direction : Vector2, senderRpcID : int = -1):
	if playerMap.has(senderRpcID):
		var playerAgentID : int = playerMap.get(senderRpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent:
			if direction != Vector2.ZERO:
				var newPos : Vector2 = direction.normalized() * Vector2(16,16) + agent.position
				var path = NavigationServer2D.map_get_path(agent.agent.get_navigation_map(), agent.position, newPos, true)
				var pathLength = 0
				for i in range(0, path.size() - 1):
					pathLength += Vector2(path[i] - path[i+1]).length_squared()
				if pathLength <= 500:
					SetClickPos(newPos, senderRpcID)
				else:
					print(pathLength)

#
func ConnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer connected: %s" % id)

func DisconnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer disconnected: %s" % id)
