extends ServiceBase

#
var Client							= null
var Server							= null

var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= NetworkCommons.RidDefault

enum EChannel
{
	CONNECT = 0,
	ACTION,
	MAP,
	NAVIGATION,
	ENTITY,
}

# Connection
@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func ConnectPlayer(playerName : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("ConnectPlayer", [playerName], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DisconnectPlayer(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("DisconnectPlayer", [], rpcID)

# Respawn
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerRespawn(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerRespawn", [], rpcID)

# Warp
@rpc("any_peer", "call_remote", "unreliable", EChannel.MAP)
func TriggerWarp(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerWarp", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.MAP) 
func WarpPlayer(mapName : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("WarpPlayer", [mapName], rpcID)

# Entities
@rpc("authority", "call_remote", "reliable", EChannel.MAP) 
func AddEntity(agentID : int, entityType : EntityCommons.Type, entityID : String, entityName : String, velocity : Vector2, position : Vector2i, orientation : Vector2, entityState : EntityCommons.State, skillCastName : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("AddEntity", [agentID, entityType, entityID, entityName, velocity, position, orientation, entityState, skillCastName], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.MAP) 
func RemoveEntity(agentID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("RemoveEntity", [agentID], rpcID)

# Notification
@rpc("any_peer", "call_remote", "unreliable_ordered", EChannel.MAP)
func PushNotification(notif : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("PushNotification", [notif], rpcID)

# Navigation
@rpc("any_peer", "call_remote", "unreliable_ordered", EChannel.NAVIGATION)
func SetClickPos(pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("SetClickPos", [pos], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.NAVIGATION)
func SetMovePos(pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("SetMovePos", [pos], rpcID, NetworkCommons.DelayInstant)

@rpc("authority", "call_remote", "unreliable_ordered", EChannel.NAVIGATION)
func UpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : EntityCommons.State, skillCastName : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("UpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastName], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.NAVIGATION)
func ForceUpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : EntityCommons.State, skillCastName : String,  rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ForceUpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastName], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.NAVIGATION)
func ClearNavigation(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("ClearNavigation", [], rpcID)

# Emote
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerEmote(emoteID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerEmote", [emoteID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION) 
func EmotePlayer(senderAgentID : int, emoteID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("EmotePlayer", [senderAgentID, emoteID], rpcID)

# Sit
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerSit(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerSit", [], rpcID)

# Chat
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerChat(text : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerChat", [text], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ChatAgent(ridAgent : int, text : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ChatAgent", [ridAgent, text], rpcID)

# Interact
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerInteract(entityID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerInteract", [entityID], rpcID, 1000)

# Combat
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerCast(entityID : int, skillName : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerCast", [entityID, skillName], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func TargetAlteration(agentID : int, targetID : int, value : int, alteration : EntityCommons.Alteration, skillName : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("TargetAlteration", [agentID, targetID, value, alteration, skillName], rpcID)

# Morph
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerMorph(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerMorph", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func Morphed(agentID : int, morphID : String, notifyMorphing : bool, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("Morphed", [agentID, morphID, notifyMorphing], rpcID)

# Stats
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdatePlayerVars(level : int, experience : float, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("UpdatePlayerVars", [level, experience], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateActiveStats(health : int, mana : int, stamina : int, weight : float, morphed : bool, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("UpdateActiveStats", [health, mana, stamina, weight, morphed], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdatePersonalStats(strength : int, vitality : int, agility : int, endurance : int, concentration : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("UpdatePersonalStats", [strength, vitality, agility, endurance, concentration], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func TargetLevelUp(targetID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("TargetLevelUp", [targetID], rpcID)

#
func NetSpamControl(rpcID : int, methodName : String, actionDelta : int) -> bool:
	if Server:
		if not Server.playerMap.has(rpcID):
			Server.AddPlayerData(rpcID)
		if Server.CallMethod(rpcID, methodName, actionDelta):
			return true
	return false

func NetCallServer(methodName : String, args : Array, rpcID : int, actionDelta : int = NetworkCommons.DelayDefault):
	if Server:
		if NetSpamControl(rpcID, methodName, actionDelta):
			Server.callv(methodName, args + [rpcID])
	else:
		callv("rpc_id", [1, methodName] + args + [uniqueID])

func NetCallClient(methodName : String, args : Array, rpcID : int):
	if Client:
		Client.callv(methodName, args)
	else:
		callv("rpc_id", [rpcID, methodName] + args)

func NetCallClientGlobal(methodName : String, args : Array):
	if Client:
		Client.callv(methodName, args)
	else:
		callv("rpc", [methodName] + args)

func NetMode(isClient : bool, isServer : bool):
	if isClient:
		Client = FileSystem.LoadSource("network/Client.gd")
	if isServer:
		Server = FileSystem.LoadSource("network/Server.gd")

func NetCreate():
	if uniqueID != NetworkCommons.RidDefault:
		pass

	if Client and Server:
		ConnectPlayer(Launcher.FSM.playerName)
		uniqueID = NetworkCommons.RidSingleMode
	elif Client:
		var serverAddress : String = NetworkCommons.LocalServerAddress if Launcher.Debug else NetworkCommons.ServerAddress
		var ret : Error = peer.create_client(serverAddress, NetworkCommons.ServerPort)
		Util.Assert(ret == OK, "Client could not connect, please check the server adress %s and port number %d" % [serverAddress, NetworkCommons.ServerPort])
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			var connectedCallback : Callable = ConnectPlayer.bind(Launcher.FSM.playerName) 
			if not Launcher.Root.multiplayer.connected_to_server.is_connected(connectedCallback):
				Launcher.Root.multiplayer.connected_to_server.connect(connectedCallback)
			if not Launcher.Root.multiplayer.connection_failed.is_connected(Client.DisconnectPlayer):
				Launcher.Root.multiplayer.connection_failed.connect(Client.DisconnectPlayer)
			if not Launcher.Root.multiplayer.server_disconnected.is_connected(Client.DisconnectPlayer):
				Launcher.Root.multiplayer.server_disconnected.connect(Client.DisconnectPlayer)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()
	elif Server:
		var ret : Error = peer.create_server(NetworkCommons.ServerPort, NetworkCommons.MaxPlayerCount)
		Util.Assert(ret == OK, "Server could not be created, please check if your port %d is valid" % NetworkCommons.ServerPort)
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			if not Launcher.Root.multiplayer.peer_connected.is_connected(Server.ConnectPeer):
				Launcher.Root.multiplayer.peer_connected.connect(Server.ConnectPeer)
			if not Launcher.Root.multiplayer.peer_disconnected.is_connected(Server.DisconnectPeer):
				Launcher.Root.multiplayer.peer_disconnected.connect(Server.DisconnectPeer)
			Util.PrintLog("Server", "Initialized on port %d" % NetworkCommons.ServerPort)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()

func NetDestroy():
	if uniqueID == NetworkCommons.RidDefault:
		pass

	if Client and Server:
		Client.DisconnectPlayer()
		Server.DisconnectPlayer()
	else:
		peer.close()

	uniqueID = NetworkCommons.RidDefault
