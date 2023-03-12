extends Node

var playerMap : Dictionary = {}

#
func ConnectPlayer(playerName : String, rpcID : int = -1):
	if not playerMap.has(rpcID):
		if not Launcher.World.HasAgent(playerName):
			var player : BaseAgent	= Launcher.DB.Instantiate.CreateAgent("Player", "Default Entity", playerName)
			var mapName : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
			var map : Object		= Launcher.World.areas[mapName]
			var pos : Vector2		= Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP)
			var playerID : int		= player.get_rid().get_id()

			playerMap[rpcID]				= playerID
			Launcher.World.rids[playerID]	= player

			Launcher.World.Spawn(map, pos, player)
			Launcher.Network.WarpPlayer(mapName, rpcID)

func DisconnectPlayer(rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var disconnectedAgent : BaseAgent = Launcher.World.rids[playerAgentID]
		if disconnectedAgent:
			var inst : Object = Launcher.World.GetInstanceFromAgent(disconnectedAgent, true, false, false)
			if inst:
				for player in inst.players:
					if player != disconnectedAgent:
						var playerID = Launcher.Network.Server.playerMap.find_key(player.get_rid().get_id())
						if playerID != null:
							Launcher.Network.RemoveEntity(playerAgentID, playerID)

			playerMap.erase(rpcID)
			Launcher.World.rids.erase(disconnectedAgent)
			Launcher.World.RemoveAgent(disconnectedAgent.agentName, true, false, false)

#
func GetEntities(rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var playerAgent : BaseAgent = Launcher.World.rids[playerAgentID]
		if playerAgent:
			var agents : Array[BaseAgent] = Launcher.World.GetAgents(playerAgent)
			for agent in agents:
				Launcher.Network.AddEntity(agent.get_rid().get_id(), agent.agentType, agent.agentID, agent.agentName, agent.position, agent.isSitting, rpcID)

#
func TriggerWarp(rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent && agent.get_parent():
			var currentMap : Object = Launcher.World.GetMapFromAgent(agent, true, false, false)
			Launcher.Util.Assert(currentMap != null, "Could not trigger the warp, current map is invalid")
			if currentMap:
				for warp in currentMap.warps:
					if warp and Geometry2D.is_point_in_polygon(agent.get_position(), warp.polygon):
						var nextMap : Object = Launcher.World.areas[warp.destinationMap]
						Launcher.World.Warp(agent, currentMap, nextMap, warp.destinationPos)
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
				var newPos : Vector2 = direction.normalized() * Vector2(32,32) + agent.position
				var path = NavigationServer2D.map_get_path(agent.agent.get_navigation_map(), agent.position, newPos, true)
				var pathLength = 0
				for i in range(0, path.size() - 1):
					pathLength += Vector2(path[i] - path[i+1]).length()
				if pathLength <= 48:
					SetClickPos(newPos, rpcID)

func TriggerSit(rpcID : int = -1):
	if playerMap.has(rpcID):
		var playerAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[playerAgentID]
		if agent:
			agent.isSitting = not agent.isSitting

func TriggerEmote(emoteID : int, rpcID : int = -1):
	if playerMap.has(rpcID):
		var senderAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[senderAgentID]
		if agent:
			var inst : Object = Launcher.World.GetInstanceFromAgent(agent, true, false, false)
			Launcher.Util.Assert(inst != null, "Could not trigger the emote, current map instance is invalid")
			if inst:
				for player in inst.players:
					var playerID = Launcher.Network.Server.playerMap.find_key(player.get_rid().get_id())
					if playerID != null:
						Launcher.Network.EmotePlayer(senderAgentID, emoteID, playerID)

func TriggerChat(text : String, rpcID : int = -1):
	if playerMap.has(rpcID):
		var senderAgentID : int = playerMap.get(rpcID)
		var agent : BaseAgent = Launcher.World.rids[senderAgentID]
		if agent:
			var inst : Object = Launcher.World.GetInstanceFromAgent(agent, true, false, false)
			Launcher.Util.Assert(inst != null, "Could not trigger the emote, current map instance is invalid")
			if inst:
				for player in inst.players:
					var playerID = Launcher.Network.Server.playerMap.find_key(player.get_rid().get_id())
					if playerID != null:
						Launcher.Network.ChatPlayer(senderAgentID, text, playerID)

#
func ConnectPeer(rpcID : int):
	Launcher.Util.PrintLog("Server", "Peer connected: %s" % rpcID)

func DisconnectPeer(rpcID : int):
	Launcher.Util.PrintLog("Server", "Peer disconnected: %s" % rpcID)
	if rpcID in playerMap:
		if playerMap[rpcID] in Launcher.World.rids:
			DisconnectPlayer(rpcID)
