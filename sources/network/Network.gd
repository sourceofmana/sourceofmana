extends Node

#
signal peer_update
signal accounts_list_update
signal characters_list_update
signal online_accounts_update
signal online_characters_update
signal online_agents_update

#
var Client							= null
var ENetServer						= null
var WebSocketServer					= null

enum EChannel
{
	CONNECT = 0,
	ACTION,
	MAP,
	NAVIGATION,
	ENTITY,
	BULK,
}

# Auth
@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func CreateAccount(accountName : String, password : String, email : String, rpcID : int = NetworkCommons.RidSingleMode) -> bool:
	return CallServer("CreateAccount", [accountName, password, email], rpcID, NetworkCommons.DelayLogin)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func ConnectAccount(accountName : String, password : String, rpcID : int = NetworkCommons.RidSingleMode) -> bool:
	return CallServer("ConnectAccount", [accountName, password], rpcID, NetworkCommons.DelayLogin)

@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func AuthError(err : NetworkCommons.AuthError, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("AuthError", [err], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DisconnectAccount(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("DisconnectAccount", [], rpcID)

# Character
@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func CharacterInfo(info : Dictionary, equipment : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("CharacterInfo", [info, equipment], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func CreateCharacter(charName : String, traits : Dictionary, attributes : Dictionary, rpcID : int = NetworkCommons.RidSingleMode) -> bool:
	return CallServer("CreateCharacter", [charName, traits, attributes], rpcID, NetworkCommons.DelayLogin)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DeleteCharacter(charName : String, rpcID : int = NetworkCommons.RidSingleMode) -> bool:
	return CallServer("DeleteCharacter", [charName], rpcID, NetworkCommons.DelayLogin)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func ConnectCharacter(nickname : String, rpcID : int = NetworkCommons.RidSingleMode) -> bool:
	return CallServer("ConnectCharacter", [nickname], rpcID, NetworkCommons.DelayLogin)

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
func WarpPlayer(mapID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("WarpPlayer", [mapID], rpcID)

# Entities
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func AddEntity(agentID : int, entityType : ActorCommons.Type, currentShape : int, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("AddEntity", [agentID, entityType, currentShape, velocity, position, orientation, state, skillCastID], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func AddPlayer(agentID : int, entityType : ActorCommons.Type, shape : int, spirit : int, currentShape : int, nick : String, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastID : int, level : int, health : int, hairstyle : int, haircolor : int, gender : ActorCommons.Gender, race : int, skintone : int, equipments : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("AddPlayer", [agentID, entityType, shape, spirit, currentShape, nick, velocity, position, orientation, state, skillCastID, level, health, hairstyle, haircolor, gender, race, skintone, equipments], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
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
func UpdateEntity(agentID : int, velocity : Vector2, position : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateEntity", [agentID, velocity, position], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.NAVIGATION)
func FullUpdateEntity(agentID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : ActorCommons.State, skillCastID : int,  rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("FullUpdateEntity", [agentID, velocity, position, orientation, agentState, skillCastID], rpcID)

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
	CallServer("TriggerCast", [entityID, skillID], rpcID, NetworkCommons.DelayShort)

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
func Morphed(agentID : int, morphID : int, notifyMorphing : bool, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("Morphed", [agentID, morphID, notifyMorphing], rpcID)

# Stats
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdatePublicStats(agentID : int, level : int, health : int, hairstyle : int, haircolor : int, gender : ActorCommons.Gender, race : int, skintone : int, currentShape : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdatePublicStats", [agentID, level, health, hairstyle, haircolor, gender, race, skintone, currentShape], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdatePrivateStats(experience : int, gp : int, mana : int, stamina : int, karma : int, weight : float, shape : int, spirit : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdatePrivateStats", [experience, gp, mana, stamina, karma, weight, shape, spirit], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateAttributes(strength : int, vitality : int, agility : int, endurance : int, concentration : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateAttributes", [strength, vitality, agility, endurance, concentration], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func TriggerSelect(entityID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("TriggerSelect", [entityID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func AddAttribute(stat : ActorCommons.Attribute, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("AddAttribute", [stat], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func LevelUp(agentID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("LevelUp", [agentID], rpcID)

# Inventory
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemAdded(itemID : int, customfield : StringName, count : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ItemAdded", [itemID, customfield, count], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemRemoved(itemID : int, customfield : StringName, count : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ItemRemoved", [itemID, customfield, count], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemEquiped(agentID : int, itemID : int, customfield : StringName, state : bool, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("ItemEquiped", [agentID, itemID, customfield, state], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func UseItem(itemID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("UseItem", [itemID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func DropItem(itemID : int, customfield : StringName, itemCount : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("DropItem", [itemID, customfield, itemCount], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func EquipItem(itemID : int, customfield : StringName, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("EquipItem", [itemID, customfield], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func UnequipItem(itemID : int, customfield : StringName, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("UnequipItem", [itemID, customfield], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func RetrieveInventory(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("RetrieveInventory", [], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshInventory(cells : Array[Dictionary], rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("RefreshInventory", [cells], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshEquipments(agentID : int, equipments : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("RefreshEquipments", [agentID, equipments], rpcID)

# Drop
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropAdded(dropID : int, itemID : int, customfield : StringName, pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("DropAdded", [dropID, itemID, customfield, pos], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropRemoved(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("DropRemoved", [dropID], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func PickupDrop(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("PickupDrop", [dropID], rpcID)

# Progress
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateSkill(skillID : int, level : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateSkill", [skillID, level], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateBestiary(mobID : int, count : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateBestiary", [mobID, count], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateQuest(questID : int, state : int, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("UpdateQuest", [questID, state], rpcID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshProgress(skills : Dictionary, quests : Dictionary, bestiary : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	CallClient("RefreshProgress", [skills, quests, bestiary], rpcID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func RetrieveCharacterInformation(rpcID : int = NetworkCommons.RidSingleMode):
	CallServer("RetrieveCharacterInformation", [], rpcID)

# Bulk RPC calls
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func BulkCall(methodName : StringName, bulkedArgs : Array, rpcID : int = NetworkCommons.RidSingleMode):
	if rpcID == NetworkCommons.RidSingleMode:
		for args in bulkedArgs:
			Client.callv.call_deferred(methodName, args)
	elif Peers.IsUsingWebSocket(rpcID):
		WebSocketServer.multiplayerAPI.rpc(rpcID, self, "BulkCall", [methodName, bulkedArgs])
	else:
		ENetServer.multiplayerAPI.rpc(rpcID, self, "BulkCall", [methodName, bulkedArgs])

func Bulk(methodName : StringName, args : Array, rpcID : int):
	if Peers.IsUsingWebSocket(rpcID):
		WebSocketServer.Bulk(methodName, args, rpcID)
	else:
		ENetServer.Bulk(methodName, args, rpcID)

# Notify peers
func NotifyNeighbours(agent : BaseAgent, callbackName : StringName, args : Array, inclusive : bool = true, bulk : bool = false):
	if not agent:
		assert(false, "Agent is misintantiated, could not notify instance players with " + callbackName)
		return

	var currentAgentID = agent.get_rid().get_id()
	if inclusive and agent is PlayerAgent:
		if bulk:
			Network.Bulk(callbackName, [currentAgentID] + args, agent.rpcRID)
		else:
			Network.callv(callbackName, [currentAgentID] + args + [agent.rpcRID])

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	if inst:
		for player in inst.players:
			if player != null and player != agent and player.rpcRID != NetworkCommons.RidUnknown:
				if bulk:
					Network.Bulk(callbackName, [currentAgentID] + args, player.rpcRID)
				else:
					Network.callv(callbackName, [currentAgentID] + args + [player.rpcRID])

func NotifyInstance(inst : WorldInstance, callbackName : StringName, args : Array):
	if inst:
		for player in inst.players:
			if player != null:
				if player.rpcRID != NetworkCommons.RidUnknown:
					Network.callv(callbackName, args + [player.rpcRID])

# Peer calls
func CallServer(methodName : StringName, args : Array, rpcID : int, actionDelta : int = NetworkCommons.DelayDefault) -> bool:
	if rpcID == NetworkCommons.RidSingleMode and not Client.isOffline:
		if Peers.Footprint(rpcID, methodName, actionDelta):
			Client.multiplayerAPI.rpc(NetworkCommons.RidAuthority, self, methodName, args + [Client.uniqueID])
			return true
	else:
		if Peers.Footprint(rpcID, methodName, actionDelta):
			if Peers.IsUsingWebSocket(rpcID):
				WebSocketServer.callv.call_deferred(methodName, args + [rpcID])
			else:
				ENetServer.callv.call_deferred(methodName, args + [rpcID])
			return true
	return false

func CallClient(methodName : StringName, args : Array, rpcID : int):
	if rpcID == NetworkCommons.RidSingleMode:
		Client.callv.call_deferred(methodName, args)
	elif Peers.IsUsingWebSocket(rpcID):
		WebSocketServer.multiplayerAPI.rpc(rpcID, self, methodName, args)
	else:
		ENetServer.multiplayerAPI.rpc(rpcID, self, methodName, args)

# Service handling
func Mode(isClient : bool, isServer : bool):
	var isOffline : bool = isClient and isServer
	if isClient:
		Client = NetClient.new(LauncherCommons.isWeb, isOffline, isOffline or NetworkCommons.IsLocal, NetworkCommons.IsTesting)

	if isServer:
		if NetworkCommons.UseENet:
			ENetServer = NetServer.new(false, isOffline, NetworkCommons.IsLocal, NetworkCommons.IsTesting)
		if NetworkCommons.UseWebSocket and not isOffline:
			WebSocketServer = NetServer.new(true, isOffline, NetworkCommons.IsLocal, NetworkCommons.IsTesting)

func _init():
	if not NetworkCommons.OnlineListPath.is_empty():
		online_agents_update.connect(OnlineList.UpdateJson)

func Destroy():
	if Client:
		Client.Destroy()
		Client = null
	if ENetServer:
		ENetServer.Destroy()
		ENetServer = null
	if WebSocketServer:
		WebSocketServer.Destroy()
		WebSocketServer = null
