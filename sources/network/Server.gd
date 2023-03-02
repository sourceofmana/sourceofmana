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
			Launcher.Network.WarpPlayer(map, rpcID)

func DisconnectPlayer(playerName : String, rpcID : int = -1):
	if playerMap.has(rpcID):
		playerMap.erase(rpcID)
		Launcher.World.RemoveAgent(playerName, true, false, false)

#
func GetAgents(rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var playerAgent : BaseAgent = Launcher.World.rids[playerAgentID]
		if playerAgent:
			var agents : Array[BaseAgent] = Launcher.World.GetAgents(playerAgent)
			for agent in agents:
				Launcher.Network.AddEntity(agent.get_rid().get_id(), agent.agentType, agent.agentID, agent.agentName, agent.position, rpcID)

#
func TriggerWarp(rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent && agent.get_parent():
			var currentMap = Launcher.World.GetMapFromAgent(agent, true, false, false)
			if currentMap:
				for warp in currentMap.warps:
					if warp and Geometry2D.is_point_in_polygon(agent.get_position(), warp.polygon):
						Launcher.World.Warp(agent.agentName, currentMap.name, warp.destinationMap, warp.destinationPos)
						Launcher.Network.WarpPlayer(warp.destinationMap, rpcID)
						break

func SetClickPos(pos : Vector2, rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent:
			agent.WalkToward(pos)

func SetMovePos(direction : Vector2, rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent:
			if direction != Vector2.ZERO:
				var newPos : Vector2 = direction.normalized() * Vector2(16,16) + agent.position
				var path = NavigationServer2D.map_get_path(agent.agent.get_navigation_map(), agent.position, newPos, true)
				var pathLength = 0
				for i in range(0, path.size() - 1):
					pathLength += Vector2(path[i] - path[i+1]).length()
				if pathLength <= 32:
					SetClickPos(newPos, rpcID)

func TriggerSit(rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent:
			agent.isSitting = not agent.isSitting

#
func ConnectPeer(rpcID : int):
	Launcher.Util.PrintLog("[Server] Peer connected: %s" % rpcID)

func DisconnectPeer(rpcID : int):
	Launcher.Util.PrintLog("[Server] Peer disconnected: %s" % rpcID)
	if rpcID in playerMap:
		if playerMap[rpcID] in Launcher.World.rids:
			DisconnectPlayer(Launcher.World.rids[playerMap[rpcID]].agentName, rpcID)
