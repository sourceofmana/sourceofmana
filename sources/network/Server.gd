extends Node

var playerMap : Dictionary			= {}
var onlineList : OnlineList			= OnlineList.new()

#
func ConnectPlayer(playerName : String, rpcID : int = -1):
	if not GetAgent(rpcID):
		var player : BaseAgent	= Instantiate.CreateAgent("Player", "Default Entity", playerName)
		var mapName : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
		var pos : Vector2		= Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP)
		var map : World.Map		= Launcher.World.GetMap(mapName)

		playerMap[rpcID]				= player.get_rid().get_id()
		WorldAgent.AddAgent(player)
		Launcher.World.Spawn(map, pos, player)

		onlineList.UpdateJson()
		Util.PrintLog("Server", "Player connected: %s (%d)" % [playerName, rpcID])

func DisconnectPlayer(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		WorldAgent.RemoveAgent(player)
		playerMap.erase(rpcID)
		Util.PrintLog("Server", "Player disconnected: %s (%d)" % [player.agentName, rpcID])

#
func GetEntities(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var list : Array[Array] = WorldAgent.GetAgentsFromAgent(player)
		for agents in list:
			for agent in agents:
				Launcher.Network.AddEntity(agent.get_rid().get_id(), agent.agentType, agent.agentID, agent.agentName, agent.position, agent.currentState, rpcID)
				Launcher.Network.ForceUpdateEntity(agent.get_rid().get_id(), agent.velocity, agent.position, agent.currentState, rpcID)

func SetClickPos(pos : Vector2, rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.WalkToward(pos)

func SetMovePos(direction : Vector2, rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var pos : Vector2 = direction.normalized() * Vector2(32,32) + player.position
		if WorldNavigation.GetPathLength(player, pos) <= 48:
			player.WalkToward(pos)

func TriggerWarp(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var warp : WarpObject = Launcher.World.CanWarp(player)
		if warp:
			var nextMap : World.Map = Launcher.World.GetMap(warp.destinationMap)
			if nextMap:
				Launcher.World.Warp(player, nextMap, warp.destinationPos)

func TriggerSit(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.SetState(EntityCommons.State.SIT)

func TriggerEmote(emoteID : int, rpcID : int = -1):
	NotifyInstancePlayers(null, GetAgent(rpcID), "EmotePlayer", [emoteID])

func TriggerChat(text : String, rpcID : int = -1):
	NotifyInstancePlayers(null, GetAgent(rpcID), "ChatAgent", [text])

func TriggerEntity(triggeredAgentID : int, rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var triggeredAgent : BaseAgent = WorldAgent.GetAgent(triggeredAgentID)
		if triggeredAgent:
			triggeredAgent.Trigger(player)

func TriggerMorph(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player and player.stat and player.stat.spiritShape.length() > 0:
		var morphID : String = player.stat.spiritShape if not player.stat.morphed else player.stat.entityShape
		if morphID.length() > 0:
			var morphData : EntityData = Instantiate.FindEntityReference(morphID)
			player.stat.Morph(morphData)
			NotifyInstancePlayers(null, player, "Morphed", [morphID])

#
func GetRid(player : PlayerAgent) -> int:
	var agentRid : int = player.get_rid().get_id()
	return playerMap.find_key(agentRid)

func GetAgent(rpcID : int) -> BaseAgent:
	var agent : BaseAgent	= null
	if playerMap.has(rpcID):
		var agentID : int = playerMap.get(rpcID)
		agent = WorldAgent.GetAgent(agentID)
		Util.Assert(agent != null, "Agent ID %d is not initialized, could not retrieve the base agent" % [agentID])
	return agent

func NotifyInstancePlayers(inst : SubViewport, agent : BaseAgent, callbackName : String, args : Array, inclusive : bool = true):
	if not inst:
		inst = WorldAgent.GetInstanceFromAgent(agent)
	Util.Assert(inst != null, "Could not notify every peer as this agent (%s) is not connected to any instance!" % agent.agentName)
	if inst:
		var currentPlayerID = agent.get_rid().get_id()
		if currentPlayerID != null:
			for player in inst.players:
				var playerID = player.get_rid().get_id()
				var peerID = playerMap.find_key(playerID)
				if peerID != null && (inclusive || playerID != currentPlayerID):
					Launcher.Network.callv(callbackName, [currentPlayerID] + args + [peerID])

#
func ConnectPeer(rpcID : int):
	Util.PrintLog("Server", "Peer connected: %d" % rpcID)

func DisconnectPeer(rpcID : int):
	Util.PrintLog("Server", "Peer disconnected: %d" % rpcID)
	if rpcID in playerMap:
		if WorldAgent.GetAgent(playerMap[rpcID]):
			DisconnectPlayer(rpcID)
