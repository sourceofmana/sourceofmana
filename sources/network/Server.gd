extends Node

var playerMap : Dictionary			= {}
var onlineList : OnlineList			= OnlineList.new()

class PlayerData:
	var agentRID : int				= Launcher.Network.RidSingleMode
	var rpcDeltas : Dictionary		= {}

#
func AddPlayerData(networkRpcID : int):
	if not networkRpcID in playerMap:
		playerMap[networkRpcID] = PlayerData.new()

func CallMethod(networkRpcID : int, methodName : String, actionDelta : int) -> bool:
	Util.Assert(networkRpcID in playerMap, "Could not find data related to this player: " + str(networkRpcID))
	if networkRpcID in playerMap:
		var oldTick : int = 0
		if methodName in playerMap[networkRpcID].rpcDeltas:
			oldTick = playerMap[networkRpcID].rpcDeltas[methodName]

		var currentTick : int = Time.get_ticks_msec()
		if oldTick + actionDelta <= currentTick:
			playerMap[networkRpcID].rpcDeltas[methodName] = currentTick
			return true

	return false

#
func ConnectPlayer(nickname : String, rpcID : int = Launcher.Network.RidSingleMode):
	if not GetAgent(rpcID) and not nickname in onlineList.GetPlayerNames():
		var agent : BaseAgent = Instantiate.CreateAgent("Player", "Default Entity", nickname)
		playerMap[rpcID].agentRID = agent.get_rid().get_id()
		WorldAgent.CreateAgent(Launcher.World.defaultSpawn, 0, agent)

		onlineList.UpdateJson()
		Util.PrintLog("Server", "Player connected: %s (%d)" % [nickname, rpcID])
	elif rpcID != Launcher.Network.RidSingleMode:
		Launcher.Network.peer.disconnect_peer(rpcID)

func DisconnectPlayer(rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		WorldAgent.RemoveAgent(player)
		playerMap.erase(rpcID)

		onlineList.UpdateJson()
		Util.PrintLog("Server", "Player disconnected: %s (%d)" % [player.agentName, rpcID])

#
func GetEntities(rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var neighbours : Array[Array] = WorldAgent.GetNeighboursFromAgent(player)
		for agents in neighbours:
			for agent in agents:
				Launcher.Network.AddEntity(agent.get_rid().get_id(), agent.agentType, agent.GetCurrentShapeID(), agent.agentName, agent.position, agent.currentState, rpcID)
				Launcher.Network.ForceUpdateEntity(agent.get_rid().get_id(), agent.velocity, agent.position, agent.currentState, rpcID)

func SetClickPos(pos : Vector2, rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.SetRelativeMode(false, Vector2.ZERO)
		player.WalkToward(pos)

func SetMovePos(direction : Vector2, rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.SetRelativeMode(true, direction.normalized())

func ClearNavigation(rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.SetRelativeMode(false, Vector2.ZERO)

func TriggerWarp(rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var warp : WarpObject = Launcher.World.CanWarp(player)
		if warp:
			var nextMap : World.Map = Launcher.World.GetMap(warp.destinationMap)
			if nextMap:
				Launcher.World.Warp(player, nextMap, warp.destinationPos)

func TriggerSit(rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.SetState(EntityCommons.State.SIT)

func TriggerEmote(emoteID : int, rpcID : int = Launcher.Network.RidSingleMode):
	NotifyInstancePlayers(null, GetAgent(rpcID), "EmotePlayer", [emoteID])

func TriggerChat(text : String, rpcID : int = Launcher.Network.RidSingleMode):
	NotifyInstancePlayers(null, GetAgent(rpcID), "ChatAgent", [text])

func TriggerInteract(triggeredAgentID : int, rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var triggeredAgent : BaseAgent = WorldAgent.GetAgent(triggeredAgentID)
		if triggeredAgent:
			triggeredAgent.Interact(player)

func TriggerDamage(triggeredAgentID : int, rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		var triggeredAgent : BaseAgent = WorldAgent.GetAgent(triggeredAgentID)
		if triggeredAgent:
			triggeredAgent.Damage(player)

func TriggerMorph(rpcID : int = Launcher.Network.RidSingleMode):
	var player : BaseAgent = GetAgent(rpcID)
	if player:
		player.Morph()

#
func GetRid(player : PlayerAgent) -> int:
	var playerRid : int = player.get_rid().get_id()
	for dataID in playerMap:
		if playerMap[dataID].agentRID == playerRid:
			return dataID
	Util.Assert(false, "No playerdata associated to this user within the player map")
	return Launcher.Network.RidUnknown

func GetAgent(rpcID : int) -> BaseAgent:
	var agent : BaseAgent	= null
	if rpcID in playerMap:
		var playerData : PlayerData = playerMap.get(rpcID)
		Util.Assert(playerData != null, "No playerdata associated to this user within the player map")
		if playerData:
			agent = WorldAgent.GetAgent(playerData.agentRID)

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
				var peerID = GetRid(player)
				if peerID != Launcher.Network.RidUnknown && (inclusive || playerID != currentPlayerID):
					Launcher.Network.callv(callbackName, [currentPlayerID] + args + [peerID])

#
func ConnectPeer(rpcID : int):
	Util.PrintLog("Server", "Peer connected: %d" % rpcID)

func DisconnectPeer(rpcID : int):
	Util.PrintLog("Server", "Peer disconnected: %d" % rpcID)
	if rpcID in playerMap:
		if WorldAgent.GetAgent(playerMap[rpcID].agentRID):
			DisconnectPlayer(rpcID)
