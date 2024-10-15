extends ServiceBase

#
var Client							= null
var Server							= null

var peer : MultiplayerPeer			= null
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
func AddEntity(agentID : int, entityType : ActorCommons.Type, entityID : String, nick : String, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("AddEntity", [agentID, entityType, entityID, nick, velocity, position, orientation, state, skillCastID], rpcID)

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
func UpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : ActorCommons.State, skillCastID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("UpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.NAVIGATION)
func ForceUpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : ActorCommons.State, skillCastID : int,  rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ForceUpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastID], rpcID)

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

# Context
@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ToggleContext(enable : bool, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ToggleContext", [enable], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextText(author : String, text : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ContextText", [author, text], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextContinue(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ContextContinue", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextClose(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ContextClose", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextChoice(texts : PackedStringArray, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ContextChoice", [texts], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerChoice(choiceID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerChoice", [choiceID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerCloseContext(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerCloseContext", [], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerNextContext(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerNextContext", [], rpcID)

# Interact
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerInteract(entityID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerInteract", [entityID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerExplore(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerExplore", [], rpcID)

# Combat
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerCast(entityID : int, skillID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerCast", [entityID, skillID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func TargetAlteration(agentID : int, targetID : int, value : int, alteration : ActorCommons.Alteration, skillID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("TargetAlteration", [agentID, targetID, value, alteration, skillID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func Casted(agentID : int, skillID: int, cooldown : float, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("Casted", [agentID, skillID, cooldown], rpcID)

# Morph
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerMorph(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerMorph", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func Morphed(agentID : int, morphID : String, notifyMorphing : bool, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("Morphed", [agentID, morphID, notifyMorphing], rpcID)

# Stats
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateActiveStats(agentID : int, level : int, experience : int, gp : int, health : int, mana : int, stamina : int, weight : float, entityShape : String, spiritShape : String, currentShape : String, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("UpdateActiveStats", [agentID, level, experience, gp, health, mana, stamina, weight, entityShape, spiritShape, currentShape], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateAttributes(agentID : int, strength : int, vitality : int, agility : int, endurance : int, concentration : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("UpdateAttributes", [agentID, strength, vitality, agility, endurance, concentration], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func TargetLevelUp(targetID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("TargetLevelUp", [targetID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func TriggerSelect(entityID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("TriggerSelect", [entityID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func AddAttribute(stat : ActorCommons.Attribute, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("AddAttribute", [stat], rpcID)

# Items
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemAdded(itemID : int, count : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ItemAdded", [itemID, count], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemRemoved(itemID : int, count : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("ItemRemoved", [itemID, count], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func UseItem(itemID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("UseItem", [itemID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func RetrieveInventory(rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("RetrieveInventory", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshInventory(cells : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("RefreshInventory", [cells], rpcID)

# Drop
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropAdded(dropID : int, itemID : int, pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("DropAdded", [dropID, itemID, pos], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropRemoved(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallClient("DropRemoved", [dropID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func PickupDrop(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	NetCallServer("PickupDrop", [dropID], rpcID)

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
			Server.callv.call_deferred(methodName, args + [rpcID])
	else:
		callv.call("rpc_id", [1, methodName] + args + [uniqueID])

func NetCallClient(methodName : String, args : Array, rpcID : int):
	if Client:
		Client.callv.call_deferred(methodName, args)
	else:
		callv.call("rpc_id", [rpcID, methodName] + args)

func NetCallClientGlobal(methodName : String, args : Array):
	if Client:
		Client.callv.call_deferred(methodName, args)
	else:
		callv.call("rpc", [methodName] + args)

func NetMode(isClient : bool, isServer : bool):
	if isClient:
		Client = FileSystem.LoadSource("network/Client.gd")
	if isServer:
		Server = FileSystem.LoadSource("network/Server.gd")

func NetCreate():
	if uniqueID != NetworkCommons.RidDefault:
		pass

	if NetworkCommons.EnableWebSocket:
		peer = WebSocketMultiplayerPeer.new()
	else:
		peer = ENetMultiplayerPeer.new()

	if Client and Server:
		ConnectPlayer(Launcher.FSM.playerName)
		uniqueID = NetworkCommons.RidSingleMode
	elif Client:
		var ret : Error = FAILED
		var serverAddress : String = NetworkCommons.LocalServerAddress if Launcher.Debug else NetworkCommons.ServerAddress
		if NetworkCommons.EnableWebSocket:
			var tlsOptions : TLSOptions = null
			var prefix : String = "ws://"
			if ResourceLoader.exists(NetworkCommons.ClientTrustedCAPath):
				var clientTrustedCA : X509Certificate = ResourceLoader.load(NetworkCommons.ClientTrustedCAPath)
				tlsOptions = TLSOptions.client(clientTrustedCA)
				prefix = "wss://"
			ret = peer.create_client(prefix + serverAddress + ":" + str(NetworkCommons.ServerPort), tlsOptions)
		else:
			ret = peer.create_client(serverAddress, NetworkCommons.ServerPort)

		assert(ret == OK, "Client could not connect, please check the server adress %s and port number %d" % [serverAddress, NetworkCommons.ServerPort])
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			var connectedCallback : Callable = Launcher.FSM.EnterState.bind(Launcher.FSM.States.CHAR_SCREEN)
			if not Launcher.Root.multiplayer.connected_to_server.is_connected(connectedCallback):
				Launcher.Root.multiplayer.connected_to_server.connect(connectedCallback)
			if not Launcher.Root.multiplayer.connection_failed.is_connected(Client.DisconnectPlayer):
				Launcher.Root.multiplayer.connection_failed.connect(Client.DisconnectPlayer)
			if not Launcher.Root.multiplayer.server_disconnected.is_connected(Client.DisconnectPlayer):
				Launcher.Root.multiplayer.server_disconnected.connect(Client.DisconnectPlayer)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()
	elif Server:
		var ret : Error = FAILED
		if NetworkCommons.EnableWebSocket:
			var serverKey : CryptoKey = null
			var serverCerts : X509Certificate = null
			var tlsOptions : TLSOptions = null
			if ResourceLoader.exists(NetworkCommons.ServerKeyPath) and ResourceLoader.exists(NetworkCommons.ServerCertsPath):
				serverKey = ResourceLoader.load(NetworkCommons.ServerKeyPath)
				serverCerts = ResourceLoader.load(NetworkCommons.ServerCertsPath)
				tlsOptions = TLSOptions.server(serverKey, serverCerts)
			ret = peer.create_server(NetworkCommons.ServerPort, "*", tlsOptions)
		else:
			ret = peer.create_server(NetworkCommons.ServerPort)
		assert(ret == OK, "Server could not be created, please check if your port %d is valid" % NetworkCommons.ServerPort)
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			if not Launcher.Root.multiplayer.peer_connected.is_connected(Server.ConnectPeer):
				Launcher.Root.multiplayer.peer_connected.connect(Server.ConnectPeer)
			if not Launcher.Root.multiplayer.peer_disconnected.is_connected(Server.DisconnectPeer):
				Launcher.Root.multiplayer.peer_disconnected.connect(Server.DisconnectPeer)
			Util.PrintLog("Server", "Initialized on port %d" % NetworkCommons.ServerPort)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()

func NetDestroy():
	if peer:
		peer.close()
	if Client:
		Client.DisconnectPlayer()
		Client.queue_free()
		Client = null
	if Server:
		Server.DisconnectPlayer()
		Server.queue_free()
		Server = null
	uniqueID = NetworkCommons.RidDefault

func _post_launch():
	isInitialized = true
