extends ServiceBase

#
var Client							= null
var Server							= null

const RidUnknown : int			= -2
const RidSingleMode : int		= -1
const RidDefault : int			= 0

const DelayInstant : int		= 0
const DelayDefault : int		= 50

const LocalhostIP : String = "127.0.0.1"

var peer : ENetMultiplayerPeer		= ENetMultiplayerPeer.new()
var uniqueID : int					= RidDefault

# Connection
@rpc("any_peer", "reliable")
func ConnectPlayer(playerName : String, rpcID : int = RidSingleMode):
	NetCallServer("ConnectPlayer", [playerName], rpcID)

@rpc("any_peer", "reliable")
func DisconnectPlayer(rpcID : int = RidSingleMode):
	NetCallServer("DisconnectPlayer", [], rpcID)

# Warp
@rpc("any_peer", "unreliable")
func TriggerWarp(rpcID : int = RidSingleMode):
	NetCallServer("TriggerWarp", [], rpcID)

@rpc("authority", "reliable") 
func WarpPlayer(mapName : String, rpcID : int = RidSingleMode):
	NetCallClient("WarpPlayer", [mapName], rpcID)

# Emote
@rpc("any_peer", "reliable")
func TriggerEmote(emoteID : int, rpcID : int = RidSingleMode):
	NetCallServer("TriggerEmote", [emoteID], rpcID)

@rpc("authority", "reliable")
func EmotePlayer(senderAgentID : int, emoteID : int, rpcID : int = RidSingleMode):
	NetCallClient("EmotePlayer", [senderAgentID, emoteID], rpcID)

# Entities
@rpc("authority", "reliable")
func AddEntity(agentID : int, entityType : EntityCommons.Type, entityID : String, entityName : String, velocity : Vector2, position : Vector2i, orientation : Vector2, entityState : EntityCommons.State, skillCastID : int, rpcID : int = RidSingleMode):
	NetCallClient("AddEntity", [agentID, entityType, entityID, entityName, velocity, position, orientation, entityState, skillCastID], rpcID)

@rpc("authority", "reliable")
func RemoveEntity(agentID : int, rpcID : int = RidSingleMode):
	NetCallClient("RemoveEntity", [agentID], rpcID)

# Navigation
@rpc("any_peer", "unreliable_ordered")
func SetClickPos(pos : Vector2, rpcID : int = RidSingleMode):
	NetCallServer("SetClickPos", [pos], rpcID)

@rpc("any_peer", "reliable")
func SetMovePos(pos : Vector2, rpcID : int = RidSingleMode):
	NetCallServer("SetMovePos", [pos], rpcID, DelayInstant)

@rpc("authority", "unreliable_ordered")
func UpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : EntityCommons.State, skillCastID : int, rpcID : int = RidSingleMode):
	NetCallClient("UpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastID], rpcID)

@rpc("authority", "reliable")
func ForceUpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : EntityCommons.State, skillCastID : int,  rpcID : int = RidSingleMode):
	NetCallClient("ForceUpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastID], rpcID)

@rpc("any_peer", "reliable")
func ClearNavigation(rpcID : int = RidSingleMode):
	NetCallServer("ClearNavigation", [], rpcID)

# Sit
@rpc("any_peer", "reliable")
func TriggerSit(rpcID : int = RidSingleMode):
	NetCallServer("TriggerSit", [], rpcID)

# Chat
@rpc("any_peer", "reliable")
func TriggerChat(text : String, rpcID : int = RidSingleMode):
	NetCallServer("TriggerChat", [text], rpcID)

@rpc("authority", "reliable")
func ChatAgent(ridAgent : int, text : String, rpcID : int = RidSingleMode):
	NetCallClient("ChatAgent", [ridAgent, text], rpcID)

# Interact
@rpc("any_peer", "unreliable_ordered")
func TriggerInteract(entityID : int, rpcID : int = RidSingleMode):
	NetCallServer("TriggerInteract", [entityID], rpcID, 1000)

# Combat
@rpc("any_peer", "reliable")
func TriggerCast(entityID : int, castID : int, rpcID : int = RidSingleMode):
	NetCallServer("TriggerCast", [entityID, castID], rpcID)

@rpc("authority", "reliable")
func TargetAlteration(agentID : int, targetID : int, value : int, alteration : EntityCommons.Alteration, skillID : int, rpcID : int = RidSingleMode):
	NetCallClient("TargetAlteration", [agentID, targetID, value, alteration, skillID], rpcID)

# Morph
@rpc("any_peer", "reliable")
func TriggerMorph(rpcID : int = RidSingleMode):
	NetCallServer("TriggerMorph", [], rpcID)

@rpc("authority", "reliable")
func Morphed(agentID : int, morphID : String, notifyMorphing : bool, rpcID : int = RidSingleMode):
	NetCallClient("Morphed", [agentID, morphID, notifyMorphing], rpcID)

# Stats
@rpc("any_peer", "unreliable_ordered")
func UpdatePlayerVars(level : int, experience : float, rpcID : int = RidSingleMode):
	NetCallClient("UpdatePlayerVars", [level, experience], rpcID)

@rpc("any_peer", "unreliable_ordered")
func UpdateActiveStats(health : int, mana : int, stamina : int, weight : float, morphed : bool, rpcID : int = RidSingleMode):
	NetCallClient("UpdateActiveStats", [health, mana, stamina, weight, morphed], rpcID)

@rpc("any_peer", "unreliable_ordered")
func UpdatePersonalStats(strength : int, vitality : int, agility : int, endurance : int, concentration : int, rpcID : int = RidSingleMode):
	NetCallClient("UpdatePersonalStats", [strength, vitality, agility, endurance, concentration], rpcID)

@rpc("any_peer", "reliable")
func TargetLevelUp(targetID : int, rpcID : int = RidSingleMode):
	NetCallClient("TargetLevelUp", [targetID], rpcID)

# Notification
@rpc("any_peer", "unreliable_ordered")
func PushNotification(notif : String, rpcID : int = RidSingleMode):
	NetCallClient("PushNotification", [notif], rpcID)

#
func NetSpamControl(rpcID : int, methodName : String, actionDelta : int) -> bool:
	if Server:
		if not Server.playerMap.has(rpcID):
			Server.AddPlayerData(rpcID)
		if Server.CallMethod(rpcID, methodName, actionDelta):
			return true
	return false

func NetCallServer(methodName : String, args : Array, rpcID : int, actionDelta : int = DelayDefault):
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
	if uniqueID != RidDefault:
		pass

	if Client and Server:
		ConnectPlayer(Launcher.FSM.playerName)
		uniqueID = RidSingleMode
	elif Client:
		var serverPort : int		= Launcher.Conf.GetInt("Server", "serverPort", Launcher.Conf.Type.NETWORK)
		var serverAddress : String	= Launcher.Conf.GetString("Server", "serverAddress", Launcher.Conf.Type.NETWORK)

		if Launcher.Debug:
			serverAddress = LocalhostIP
		var ret : Error = peer.create_client(serverAddress, serverPort)
		Util.Assert(ret == OK, "Client could not connect, please check the server adress %s and port number %d" % [serverAddress, serverPort])
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
		var serverPort : int		= Launcher.Conf.GetInt("Server", "serverPort", Launcher.Conf.Type.NETWORK)
		var maxPlayerCount : int	= Launcher.Conf.GetInt("Server", "maxPlayerCount", Launcher.Conf.Type.NETWORK)
		var ret : Error				= peer.create_server(serverPort, maxPlayerCount)

		Util.Assert(ret == OK, "Server could not be created, please check if your port %d is valid" % serverPort)
		if ret == OK:
			Launcher.Root.multiplayer.multiplayer_peer = peer
			if not Launcher.Root.multiplayer.peer_connected.is_connected(Server.ConnectPeer):
				Launcher.Root.multiplayer.peer_connected.connect(Server.ConnectPeer)
			if not Launcher.Root.multiplayer.peer_disconnected.is_connected(Server.DisconnectPeer):
				Launcher.Root.multiplayer.peer_disconnected.connect(Server.DisconnectPeer)
			Util.PrintLog("Server", "Initialized on port %d" % serverPort)

			uniqueID = Launcher.Root.multiplayer.get_unique_id()

func NetDestroy():
	if uniqueID == RidDefault:
		pass

	if Client and Server:
		Client.DisconnectPlayer()
		Server.DisconnectPlayer()
	else:
		peer.close()

	uniqueID = RidDefault
