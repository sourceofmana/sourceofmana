extends Node

var playerMap : Dictionary			= {}
var onlineList : OnlineList			= OnlineList.new()

#
func ConnectPlayer(playerName : String, rpcID : int = -1):
	if not GetAgent(rpcID):
		var player : BaseAgent	= Launcher.DB.Instantiate.CreateAgent("Player", "Default Entity", playerName)
		var mapName : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
		var map : Object		= Launcher.World.areas[mapName]
		var pos : Vector2		= Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP)
		var playerID : int		= player.get_rid().get_id()

		playerMap[rpcID]				= playerID
		Launcher.World.rids[playerID]	= player
		Launcher.World.Spawn(map, pos, player)

		onlineList.UpdateHtmlPage()
		Util.PrintLog("Server", "Player connected: %s (%d)" % [playerName, rpcID])

func DisconnectPlayer(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		Launcher.World.RemoveAgent(player)
		playerMap.erase(rpcID)
		Util.PrintLog("Server", "Player disconnected: %s (%d)" % [player.agentName, rpcID])

#
func GetEntities(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var list : Array[Array] = Launcher.World.GetAgents(player)
		for agents in list:
			for agent in agents:
				Launcher.Network.AddEntity(agent.get_rid().get_id(), agent.agentType, agent.agentID, agent.agentName, agent.position, agent.currentState, rpcID)
				Launcher.Network.ForceUpdateEntity(agent.get_rid().get_id(), agent.velocity, agent.position, agent.currentState, rpcID)

func SetClickPos(pos : Vector2, rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.ResetCombat()
		player.WalkToward(pos)

func SetMovePos(direction : Vector2, rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var pos : Vector2 = direction.normalized() * Vector2(32,32) + player.position
		if Launcher.World.GetPathLength(player, pos) <= 48:
			player.ResetCombat()
			player.WalkToward(pos)

func TriggerWarp(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		Launcher.World.CheckWarp(player)

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
		if Launcher.World.rids.has(triggeredAgentID):
			var triggeredAgent : BaseAgent = Launcher.World.rids[triggeredAgentID]
			if triggeredAgent:
				triggeredAgent.Trigger(player)

func TriggerMorph(rpcID : int = -1):
	var player : BaseAgent = GetAgent(rpcID)
	if player and player.stat:
		player.stat.morphed = not player.stat.morphed
		var entityID : String = player.stat.spirit if player.stat.morphed else "Default Entity"
		NotifyInstancePlayers(null, player, "Morphed", [entityID])

#
func GetRid(player : PlayerAgent) -> int:
	var agentRid : int = player.get_rid().get_id()
	return playerMap.find_key(agentRid)

func GetAgent(rpcID : int) -> BaseAgent:
	var agent : BaseAgent	= null
	var hasRID : bool		= playerMap.has(rpcID)
	if hasRID:
		var agentID : int = playerMap.get(rpcID)
		agent = Launcher.World.GetAgent(agentID)
		Util.Assert(agent != null, "Agent ID %d is not initialized, could not retrieve the base agent" % [agentID])
	return agent

func NotifyInstancePlayers(inst : SubViewport, agent : BaseAgent, callbackName : String, args : Array, inclusive : bool = true):
	if not inst:
		inst = Launcher.World.GetInstanceFromAgent(agent)
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
		if playerMap[rpcID] in Launcher.World.rids:
			DisconnectPlayer(rpcID)
