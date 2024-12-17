extends Node

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

# Auth
@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func CreateAccount(accountName : String, password : String, email : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("CreateAccount", [accountName, password, email], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func ConnectAccount(accountName : String, password : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("ConnectAccount", [accountName, password], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func AuthError(err : NetworkCommons.AuthError, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("AuthError", [err], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DisconnectAccount(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("DisconnectAccount", [], rpcID)

# Character
@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func CharacterInfo(info : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("CharacterInfo", [info], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func CreateCharacter(charName : String, traits : Dictionary, attributes : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("CreateCharacter", [charName, traits, attributes], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func ConnectCharacter(nickname : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("ConnectCharacter", [nickname], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func CharacterError(err : NetworkCommons.CharacterError, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("CharacterError", [err], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DisconnectCharacter(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("DisconnectCharacter", [], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func CharacterListing(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("CharacterListing", [], rpcID)

# Respawn
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerRespawn(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerRespawn", [], rpcID)

# Warp
@rpc("any_peer", "call_remote", "unreliable", EChannel.MAP)
func TriggerWarp(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerWarp", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.MAP) 
func WarpPlayer(mapName : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("WarpPlayer", [mapName], rpcID)

# Entities
@rpc("authority", "call_remote", "reliable", EChannel.MAP) 
func AddEntity(agentID : int, entityType : ActorCommons.Type, entityID : String, nick : String, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("AddEntity", [agentID, entityType, entityID, nick, velocity, position, orientation, state, skillCastID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.MAP) 
func RemoveEntity(agentID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("RemoveEntity", [agentID], rpcID)

# Notification
@rpc("any_peer", "call_remote", "unreliable_ordered", EChannel.MAP)
func PushNotification(notif : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("PushNotification", [notif], rpcID)

# Navigation
@rpc("any_peer", "call_remote", "unreliable_ordered", EChannel.NAVIGATION)
func SetClickPos(pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("SetClickPos", [pos], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.NAVIGATION)
func SetMovePos(pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("SetMovePos", [pos], rpcID, NetworkCommons.DelayInstant)

@rpc("authority", "call_remote", "unreliable_ordered", EChannel.NAVIGATION)
func UpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : ActorCommons.State, skillCastID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.NAVIGATION)
func ForceUpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : ActorCommons.State, skillCastID : int,  rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ForceUpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.NAVIGATION)
func ClearNavigation(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("ClearNavigation", [], rpcID)

# Emote
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerEmote(emoteID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerEmote", [emoteID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION) 
func EmotePlayer(senderAgentID : int, emoteID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("EmotePlayer", [senderAgentID, emoteID], rpcID)

# Sit
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerSit(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerSit", [], rpcID)

# Chat
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerChat(text : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerChat", [text], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ChatAgent(ridAgent : int, text : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ChatAgent", [ridAgent, text], rpcID)

# Context
@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ToggleContext(enable : bool, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ToggleContext", [enable], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextText(author : String, text : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ContextText", [author, text], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextContinue(rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ContextContinue", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextClose(rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ContextClose", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextChoice(texts : PackedStringArray, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ContextChoice", [texts], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerChoice(choiceID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerChoice", [choiceID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerCloseContext(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerCloseContext", [], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerNextContext(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerNextContext", [], rpcID)

# Interact
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerInteract(entityID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerInteract", [entityID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerExplore(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerExplore", [], rpcID)

# Combat
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerCast(entityID : int, skillID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerCast", [entityID, skillID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func TargetAlteration(agentID : int, targetID : int, value : int, alteration : ActorCommons.Alteration, skillID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("TargetAlteration", [agentID, targetID, value, alteration, skillID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func Casted(agentID : int, skillID: int, cooldown : float, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("Casted", [agentID, skillID, cooldown], rpcID)

# Morph
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerMorph(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerMorph", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func Morphed(agentID : int, morphID : String, notifyMorphing : bool, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("Morphed", [agentID, morphID, notifyMorphing], rpcID)

# Stats
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateActiveStats(agentID : int, level : int, experience : int, gp : int, health : int, mana : int, stamina : int, weight : float, shape : String, spirit : String, currentShape : String, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateActiveStats", [agentID, level, experience, gp, health, mana, stamina, weight, shape, spirit, currentShape], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateAttributes(agentID : int, strength : int, vitality : int, agility : int, endurance : int, concentration : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateAttributes", [agentID, strength, vitality, agility, endurance, concentration], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func TargetLevelUp(targetID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("TargetLevelUp", [targetID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func TriggerSelect(entityID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerSelect", [entityID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func AddAttribute(stat : ActorCommons.Attribute, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("AddAttribute", [stat], rpcID)

# Items
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemAdded(itemID : int, count : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ItemAdded", [itemID, count], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemRemoved(itemID : int, count : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ItemRemoved", [itemID, count], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func UseItem(itemID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("UseItem", [itemID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func RetrieveInventory(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("RetrieveInventory", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshInventory(cells : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("RefreshInventory", [cells], rpcID)

# Drop
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropAdded(dropID : int, itemID : int, pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("DropAdded", [dropID, itemID, pos], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropRemoved(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("DropRemoved", [dropID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func PickupDrop(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("PickupDrop", [dropID], rpcID)

#
func CallServer(methodName : String, args : Array, rpcID : int, actionDelta : int = NetworkCommons.DelayDefault):
	if Server:
		if Peers.Footprint(rpcID, methodName, actionDelta):
			Server.callv.call_deferred(methodName, args + [rpcID])
	else:
		callv.call("rpc_id", [1, methodName] + args + [uniqueID])

func CallClient(methodName : String, args : Array, rpcID : int):
	if Client:
		Client.callv.call_deferred(methodName, args)
	else:
		callv.call("rpc_id", [rpcID, methodName] + args)

func CallClientGlobal(methodName : String, args : Array):
	if Client:
		Client.callv.call_deferred(methodName, args)
	else:
		callv.call("rpc", [methodName] + args)

func Mode(isClient : bool, isServer : bool):
	if isClient:
		Client = FileSystem.LoadSource("network/client/Client.gd")
	if isServer:
		Server = FileSystem.LoadSource("network/server/Server.gd")

	if uniqueID != NetworkCommons.RidDefault:
		pass

	if NetworkCommons.EnableWebSocket:
		peer = WebSocketMultiplayerPeer.new()
	else:
		peer = ENetMultiplayerPeer.new()

	if Client and Server:
		uniqueID = NetworkCommons.RidSingleMode
		Server.ConnectPeer(uniqueID)
		Client.ConnectServer()
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
			Client.Init()
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
			Server.Init()
			uniqueID = Launcher.Root.multiplayer.get_unique_id()

func Destroy():
	if peer:
		peer.close()
	if Client:
		Client.Destroy()
		Client = null
	if Server:
		Server.Destroy()
		Server = null
	uniqueID = NetworkCommons.RidDefault
