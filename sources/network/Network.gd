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
func CreateAccount(accountName : String, password : String, email : String, peerID : int = NetworkCommons.PeerAuthorityID) -> bool:
	return CallServer("CreateAccount", [accountName, password, email], peerID, NetworkCommons.DelayLogin)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func ConnectAccount(accountName : String, password : String, peerID : int = NetworkCommons.PeerAuthorityID) -> bool:
	return CallServer("ConnectAccount", [accountName, password], peerID, NetworkCommons.DelayLogin)

@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func AuthError(err : NetworkCommons.AuthError, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("AuthError", [err], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DisconnectAccount(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("DisconnectAccount", [], peerID)

# Character
@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func CharacterInfo(info : Dictionary, equipment : Dictionary, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("CharacterInfo", [info, equipment], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func CreateCharacter(charName : String, traits : Dictionary, attributes : Dictionary, peerID : int = NetworkCommons.PeerAuthorityID) -> bool:
	return CallServer("CreateCharacter", [charName, traits, attributes], peerID, NetworkCommons.DelayLogin)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DeleteCharacter(charName : String, peerID : int = NetworkCommons.PeerAuthorityID) -> bool:
	return CallServer("DeleteCharacter", [charName], peerID, NetworkCommons.DelayLogin)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func ConnectCharacter(nickname : String, peerID : int = NetworkCommons.PeerAuthorityID) -> bool:
	return CallServer("ConnectCharacter", [nickname], peerID, NetworkCommons.DelayLogin)

@rpc("authority", "call_remote", "reliable", EChannel.CONNECT)
func CharacterError(err : NetworkCommons.CharacterError, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("CharacterError", [err], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func DisconnectCharacter(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("DisconnectCharacter", [], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.CONNECT)
func CharacterListing(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("CharacterListing", [], peerID)

# Respawn
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerRespawn(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerRespawn", [], peerID)

# Warp
@rpc("any_peer", "call_remote", "unreliable", EChannel.MAP)
func TriggerWarp(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerWarp", [], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.MAP) 
func WarpPlayer(mapID : int, playerPos : Vector2, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("WarpPlayer", [mapID, playerPos], peerID)

# Entities
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func AddEntity(agentRID : int, actorType : ActorCommons.Type, currentShape : int, nick : String, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastID : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("AddEntity", [agentRID, actorType, currentShape, nick, velocity, position, orientation, state, skillCastID], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func AddPlayer(agentRID : int, actorType : ActorCommons.Type, shape : int, spirit : int, currentShape : int, nick : String, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastID : int, level : int, health : int, hairstyle : int, haircolor : int, gender : ActorCommons.Gender, race : int, skintone : int, equipment : Dictionary, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("AddPlayer", [agentRID, actorType, shape, spirit, currentShape, nick, velocity, position, orientation, state, skillCastID, level, health, hairstyle, haircolor, gender, race, skintone, equipment], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RemoveEntity(agentRID : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("RemoveEntity", [agentRID], peerID)

# Notification
@rpc("any_peer", "call_remote", "unreliable_ordered", EChannel.MAP)
func PushNotification(notif : String, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("PushNotification", [notif], peerID)

# Navigation
@rpc("any_peer", "call_remote", "unreliable_ordered", EChannel.NAVIGATION)
func SetClickPos(pos : Vector2, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("SetClickPos", [pos], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.NAVIGATION)
func SetMovePos(pos : Vector2, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("SetMovePos", [pos], peerID, NetworkCommons.DelayInstant)

@rpc("authority", "call_remote", "unreliable_ordered", EChannel.ENTITY)
func UpdateEntity(agentRID : int, velocity : Vector2, position : Vector2, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("UpdateEntity", [agentRID, velocity, position], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func FullUpdateEntity(agentRID : int, velocity : Vector2, position : Vector2, orientation : Vector2, agentState : ActorCommons.State, skillCastID : int,  peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("FullUpdateEntity", [agentRID, velocity, position, orientation, agentState, skillCastID], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.NAVIGATION)
func ClearNavigation(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("ClearNavigation", [], peerID)

# Emote
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerEmote(emoteID : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerEmote", [emoteID], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION) 
func EmotePlayer(senderagentRID : int, emoteID : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("EmotePlayer", [senderagentRID, emoteID], peerID)

# Sit
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerSit(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerSit", [], peerID)

# Chat
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerChat(text : String, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerChat", [text], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ChatAgent(agentRID : int, text : String, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ChatAgent", [agentRID, text], peerID)

# Context
@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ToggleContext(enable : bool, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ToggleContext", [enable], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextText(author : String, text : String, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ContextText", [author, text], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextContinue(peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ContextContinue", [], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextClose(peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ContextClose", [], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ContextChoice(texts : PackedStringArray, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ContextChoice", [texts], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerChoice(choiceID : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerChoice", [choiceID], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerCloseContext(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerCloseContext", [], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerNextContext(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerNextContext", [], peerID)

# Interact
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerInteract(targetRID : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerInteract", [targetRID], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerExplore(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerExplore", [], peerID)

# Combat
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerCast(targetRID : int, skillID : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerCast", [targetRID, skillID], peerID, NetworkCommons.DelayShort)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func TargetAlteration(agentRID : int, targetRID : int, value : int, alteration : ActorCommons.Alteration, skillID : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("TargetAlteration", [agentRID, targetRID, value, alteration, skillID], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func Casted(agentRID : int, skillID: int, cooldown : float, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("Casted", [agentRID, skillID, cooldown], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func ThrowProjectile(agentRID : int, targetPos : Vector2, skillID: int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ThrowProjectile", [agentRID, targetPos, skillID], peerID)

# Morph
@rpc("any_peer", "call_remote", "reliable", EChannel.ACTION)
func TriggerMorph(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerMorph", [], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ACTION)
func Morphed(agentRID : int, morphID : int, notifyMorphing : bool, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("Morphed", [agentRID, morphID, notifyMorphing], peerID)

# Stats
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdatePublicStats(agentRID : int, level : int, health : int, hairstyle : int, haircolor : int, gender : ActorCommons.Gender, race : int, skintone : int, currentShape : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("UpdatePublicStats", [agentRID, level, health, hairstyle, haircolor, gender, race, skintone, currentShape], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdatePrivateStats(experience : int, gp : int, mana : int, stamina : int, karma : int, weight : float, shape : int, spirit : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("UpdatePrivateStats", [experience, gp, mana, stamina, karma, weight, shape, spirit], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateAttributes(strength : int, vitality : int, agility : int, endurance : int, concentration : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("UpdateAttributes", [strength, vitality, agility, endurance, concentration], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func TriggerSelect(agentRID : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerSelect", [agentRID], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func SetAttributes(strength, vitality, agility, endurance, concentration, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("SetAttributes", [strength, vitality, agility, endurance, concentration], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func LevelUp(agentRID : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("LevelUp", [agentRID], peerID)

# Inventory
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemAdded(itemID : int, customfield : StringName, count : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ItemAdded", [itemID, customfield, count], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemRemoved(itemID : int, customfield : StringName, count : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ItemRemoved", [itemID, customfield, count], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func ItemEquiped(agentRID : int, itemID : int, customfield : StringName, state : bool, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("ItemEquiped", [agentRID, itemID, customfield, state], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func UseItem(itemID : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("UseItem", [itemID], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func DropItem(itemID : int, customfield : StringName, itemCount : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("DropItem", [itemID, customfield, itemCount], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func EquipItem(itemID : int, customfield : StringName, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("EquipItem", [itemID, customfield], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func UnequipItem(itemID : int, customfield : StringName, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("UnequipItem", [itemID, customfield], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func RetrieveInventory(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("RetrieveInventory", [], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshInventory(cells : Array[Dictionary], peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("RefreshInventory", [cells], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshEquipment(agentRID : int, equipment : Dictionary, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("RefreshEquipment", [agentRID, equipment], peerID)

# Drop
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropAdded(dropID : int, itemID : int, customfield : StringName, pos : Vector2, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("DropAdded", [dropID, itemID, customfield, pos], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func DropRemoved(dropID : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("DropRemoved", [dropID], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func PickupDrop(dropID : int, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("PickupDrop", [dropID], peerID)

# Progress
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateSkill(skillID : int, level : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("UpdateSkill", [skillID, level], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateBestiary(mobID : int, count : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("UpdateBestiary", [mobID, count], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func UpdateQuest(questID : int, state : int, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("UpdateQuest", [questID, state], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func RefreshProgress(skills : Dictionary, quests : Dictionary, bestiary : Dictionary, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("RefreshProgress", [skills, quests, bestiary], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func RetrieveCharacterInformation(peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("RetrieveCharacterInformation", [], peerID)

# Commands
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func CommandFeedback(feedback : String, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("CommandFeedback", [feedback], peerID)

@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func CommandModifier(effect : CellCommons.Modifier, value : float, peerID : int = NetworkCommons.PeerOfflineID):
	CallClient("CommandModifier", [effect, value], peerID)

@rpc("any_peer", "call_remote", "reliable", EChannel.ENTITY)
func TriggerCommand(command : String, peerID : int = NetworkCommons.PeerAuthorityID):
	CallServer("TriggerCommand", [command], peerID)

# Bulk RPC calls
@rpc("authority", "call_remote", "reliable", EChannel.ENTITY)
func BulkCall(methodName : StringName, bulkedArgs : Array, peerID : int = NetworkCommons.PeerOfflineID):
	if WebSocketServer and not WebSocketServer.isOffline and Peers.IsUsingWebSocket(peerID):
		WebSocketServer.multiplayerAPI.rpc(peerID, self, "BulkCall", [methodName, bulkedArgs])
	elif ENetServer and not ENetServer.isOffline:
		ENetServer.multiplayerAPI.rpc(peerID, self, "BulkCall", [methodName, bulkedArgs])
	else:
		for args in bulkedArgs:
			Client.callv.call_deferred(methodName, args + [peerID])

func Bulk(methodName : StringName, args : Array, peerID : int):
	if Peers.IsUsingWebSocket(peerID):
		WebSocketServer.Bulk(methodName, args, peerID)
	else:
		ENetServer.Bulk(methodName, args, peerID)

# Notify peers
func NotifyNeighbours(agent : BaseAgent, callbackName : StringName, args : Array, inclusive : bool = true, bulk : bool = false):
	if not agent:
		assert(false, "Agent is misintantiated, could not notify instance players with " + callbackName)
		return

	var currentagentRID = agent.get_rid().get_id()
	if inclusive and agent is PlayerAgent:
		Network.callv(callbackName, [currentagentRID] + args + [agent.peerID])

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	if inst:
		for player in inst.players:
			if player != null and player != agent and player.peerID != NetworkCommons.PeerUnknownID:
				if bulk:
					Network.Bulk(callbackName, [currentagentRID] + args, player.peerID)
				else:
					Network.callv(callbackName, [currentagentRID] + args + [player.peerID])

func NotifyInstance(inst : WorldInstance, callbackName : StringName, args : Array):
	if inst:
		for player in inst.players:
			if player != null:
				if player.peerID != NetworkCommons.PeerUnknownID:
					Network.callv(callbackName, args + [player.peerID])

func NotifyArea(area : WorldMap, callbackName : StringName, args : Array):
	for inst in area.instances:
		NotifyInstance(inst, callbackName, args)

func NotifyGlobal(callbackName : StringName, args : Array):
	for areaIdx in Launcher.World.areas:
		var area = Launcher.World.areas[areaIdx]
		NotifyArea(area, callbackName, args)

# Peer calls
func CallServer(methodName : StringName, args : Array, peerID : int, actionDelta : int = NetworkCommons.DelayDefault) -> bool:
	if not Peers.Footprint(peerID, methodName, actionDelta):
		return false
	if Client and not Client.isOffline:
		Client.multiplayerAPI.rpc(peerID, self, methodName, args + [Client.interfaceID])
	elif Peers.IsUsingWebSocket(peerID):
		WebSocketServer.callv.call_deferred(methodName, args + [peerID])
	else:
		ENetServer.callv.call_deferred(methodName, args + [peerID])
	return true

func CallClient(methodName : StringName, args : Array, peerID : int):
	if WebSocketServer and not WebSocketServer.isOffline and Peers.IsUsingWebSocket(peerID):
		WebSocketServer.multiplayerAPI.rpc(peerID, self, methodName, args + [peerID])
	elif ENetServer and not ENetServer.isOffline:
		ENetServer.multiplayerAPI.rpc(peerID, self, methodName, args + [peerID])
	else:
		Client.callv.call_deferred(methodName, args + [peerID])

# Service handling
func Mode(isClient : bool, isServer : bool):
	var isOffline : bool = isClient and isServer
	if isClient:
		Client = NetClient.new(LauncherCommons.isWeb, isOffline, isOffline or NetworkCommons.IsLocal)

	if isServer:
		if NetworkCommons.UseENet:
			ENetServer = NetServer.new(false, isOffline, NetworkCommons.IsLocal)
		if NetworkCommons.UseWebSocket and not isOffline:
			WebSocketServer = NetServer.new(true, isOffline, NetworkCommons.IsLocal)

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
