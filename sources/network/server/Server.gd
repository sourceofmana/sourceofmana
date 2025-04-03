extends NetInterface
class_name NetServer

# Auth
func CreateAccount(accountName : String, password : String, email : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.AuthError = NetworkCommons.AuthError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if not peer:
		err = NetworkCommons.AuthError.ERR_NO_PEER_DATA
	else:
		err = NetworkCommons.CheckAuthInformation(accountName, password)
		if err == NetworkCommons.AuthError.ERR_OK:
			if Launcher.SQL.HasAccount(accountName):
				err = NetworkCommons.AuthError.ERR_NAME_AVAILABLE
			elif not Launcher.SQL.AddAccount(accountName, password, email):
				err = NetworkCommons.AuthError.ERR_NAME_AVAILABLE
			else:
				Network.accounts_list_update.emit()
				peer.SetAccount(Launcher.SQL.Login(accountName, password))
	Network.AuthError(err, rpcID)

func ConnectAccount(accountName : String, password : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.AuthError = NetworkCommons.AuthError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if not peer:
		err = NetworkCommons.AuthError.ERR_NO_PEER_DATA
	else:
		err = NetworkCommons.CheckAuthInformation(accountName, password)
		if err == NetworkCommons.AuthError.ERR_OK:
			peer.SetAccount(Launcher.SQL.Login(accountName, password))
			if peer.accountRID == NetworkCommons.RidUnknown:
				err = NetworkCommons.AuthError.ERR_AUTH
			else:
				Launcher.SQL.UpdateAccount(peer.accountRID)
	Network.AuthError(err, rpcID)

func DisconnectAccount(rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		if peer.accountRID != NetworkCommons.RidUnknown:
			Launcher.SQL.UpdateAccount(peer.accountRID)
			peer.SetAccount(NetworkCommons.RidUnknown)
		if peer.characterRID != NetworkCommons.RidUnknown:
			DisconnectCharacter(rpcID)

# Character
func CreateCharacter(charName : String, traits : Dictionary, attributes : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var accountID : int = Peers.GetAccount(rpcID)
	if accountID == NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		traits.merge(ActorCommons.DefaultTraits)
		if Launcher.SQL.HasCharacter(charName):
			err = NetworkCommons.CharacterError.ERR_NAME_AVAILABLE
		elif Launcher.SQL.GetCharacters(accountID).size() >= ActorCommons.MaxCharacterCount:
			err = NetworkCommons.CharacterError.ERR_SLOT_AVAILABLE
		elif not ActorCommons.CheckTraits(traits) or not ActorCommons.CheckAttributes(attributes):
			err = NetworkCommons.CharacterError.ERR_MISSING_PARAMS
		elif not Launcher.SQL.AddCharacter(accountID, charName, ActorCommons.DefaultStats, traits, attributes):
			err = NetworkCommons.CharacterError.ERR_NAME_AVAILABLE
		else:
			var characterID : int = Launcher.SQL.GetCharacterID(accountID, charName)
			if characterID == NetworkCommons.RidUnknown:
				err = NetworkCommons.CharacterError.ERR_NO_CHARACTER_ID
			else:
				Network.characters_list_update.emit()
				for itemData in ActorCommons.DefaultInventory:
					Launcher.SQL.AddItem(characterID, itemData.get("item_id", DB.UnknownHash), itemData.get("customfield", ""), itemData.get("count", 1))
				for skillData in ActorCommons.DefaultSkills:
					Launcher.SQL.SetSkill(characterID, skillData.get("skill_id", DB.UnknownHash), skillData.get("level", 1))

				Network.CharacterInfo(Launcher.SQL.GetCharacterInfo(characterID), Launcher.SQL.GetEquipment(characterID), rpcID)

	Network.CharacterError(err, rpcID)
	return err

func DeleteCharacter(charName : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer.accountRID == NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	elif peer.characterRID != NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN
	else:
		var charID : int = Launcher.SQL.GetCharacterID(peer.accountRID, charName)
		if charID == NetworkCommons.RidUnknown:
			err = NetworkCommons.CharacterError.ERR_NAME_VALID
		elif not Launcher.SQL.RemoveCharacter(charID):
			err = NetworkCommons.CharacterError.ERR_NAME_AVAILABLE
		else:
			Network.characters_list_update.emit()

	Network.CharacterError(err, rpcID)
	return err


func ConnectCharacter(nickname : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(rpcID)

	if not peer:
		err = NetworkCommons.CharacterError.ERR_NO_PEER_DATA
	elif peer.accountRID == NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		if Peers.GetCharacter(rpcID) != NetworkCommons.RidUnknown:
			err = NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN
		else:
			peer.SetCharacter(Launcher.SQL.GetCharacterID(peer.accountRID, nickname))
			if peer.characterRID == NetworkCommons.RidUnknown:
				err = NetworkCommons.CharacterError.ERR_NO_CHARACTER_ID
			else:
				var charInfo : Dictionary = Launcher.SQL.GetCharacterInfo(peer.characterRID)
				var spawnLocation : SpawnObject = PlayerAgent.GetSpawnFromData(charInfo)
				var agent : PlayerAgent = WorldAgent.CreateAgent(spawnLocation, 0, nickname)
				if agent:
					agent.rpcRID = rpcID
					peer.SetAgent(agent.get_rid().get_id())
					agent.SetCharacterInfo(charInfo, peer.characterRID)
					Launcher.SQL.CharacterLogin(peer.characterRID)
					Util.PrintLog("Server", "Player connected: %s (%d)" % [nickname, rpcID])

	Network.CharacterError(err, rpcID)

func DisconnectCharacter(rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player:
			Util.PrintLog("Server", "Player disconnected: %s (%d)" % [player.nick, rpcID])
			Launcher.SQL.RefreshCharacter(player)
			WorldAgent.RemoveAgent(player)
			peer.SetAgent(NetworkCommons.RidUnknown)
		peer.SetCharacter(NetworkCommons.RidUnknown)

func CharacterListing(rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var accountID : int = Peers.GetAccount(rpcID)
	if accountID == NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		var characterIDs : Array[int] = Launcher.SQL.GetCharacters(accountID)
		if characterIDs.is_empty():
			err = NetworkCommons.CharacterError.ERR_EMPTY_ACCOUNT
		else:
			for characterID in characterIDs:
				var charInfo : Dictionary = Launcher.SQL.GetCharacterInfo(characterID)
				var charEquipment : Dictionary = Launcher.SQL.GetEquipment(characterID)
				Network.CharacterInfo(charInfo, charEquipment, rpcID)
	Network.CharacterError(err, rpcID)

# Navigation
func SetClickPos(pos : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		player.SetRelativeMode(false, Vector2.ZERO)
		player.WalkToward(pos)

func SetMovePos(direction : Vector2, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		player.SetRelativeMode(true, direction.normalized())

func ClearNavigation(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		player.SetRelativeMode(false, Vector2.ZERO)

# Triggers
func TriggerWarp(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player and player.ownScript == null:
		var warp : WarpObject = Launcher.World.CanWarp(player)
		if warp:
			var nextMap : WorldMap = Launcher.World.GetMap(warp.destinationID)
			if nextMap:
				Launcher.World.Warp(player, nextMap, warp.getDestinationPos(player))
				if warp is PortObject:
					player.Morph(false, player.GetNextPortShapeID())

func TriggerSit(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		player.SetState(ActorCommons.State.SIT)

func TriggerRespawn(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player is PlayerAgent:
		player.Respawn()

func TriggerEmote(emoteID : int, rpcID : int = NetworkCommons.RidSingleMode):
	Network.NotifyNeighbours(Peers.GetAgent(rpcID), "EmotePlayer", [emoteID])

func TriggerChat(text : String, rpcID : int = NetworkCommons.RidSingleMode):
	Network.NotifyNeighbours(Peers.GetAgent(rpcID), "ChatAgent", [text])

func TriggerChoice(choiceID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player and player.ownScript:
		player.ownScript.InteractChoice(choiceID)

func TriggerNextContext(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player and player.ownScript and player.ownScript.npc:
		player.ownScript.npc.Interact(player)

func TriggerCloseContext(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		NpcCommons.TryCloseContext(player)

func TriggerInteract(triggeredAgentID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		var triggeredAgent : BaseAgent = WorldAgent.GetAgent(triggeredAgentID)
		if triggeredAgent:
			triggeredAgent.Interact(player)

func TriggerExplore(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player is PlayerAgent:
		player.Explore()

func TriggerCast(targetID : int, skillID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player and DB.SkillsDB.has(skillID):
		var target : BaseAgent = WorldAgent.GetAgent(targetID)
		Skill.Cast(player, target, DB.SkillsDB[skillID])

func TriggerMorph(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if not player:
		return
	if player.stat.spirit == DB.UnknownHash:
		return
	var map : Object = WorldAgent.GetMapFromAgent(player)
	if map and map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
		return
	player.Morph(true)

func TriggerSelect(targetID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var target : BaseAgent = WorldAgent.GetAgent(targetID)
	if target:
		Network.UpdatePublicStats(targetID, target.stat.level, target.stat.health, target.stat.hairstyle, target.stat.haircolor, target.stat.gender, target.stat.race, target.stat.skintone, target.stat.currentShape, rpcID)

# Stats
func AddAttribute(attribute : ActorCommons.Attribute, rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if peer and peer.characterRID != NetworkCommons.RidUnknown and player and player.stat:
		player.stat.AddAttribute(attribute)
		Launcher.SQL.UpdateAttribute(peer.characterRID, player.stat)

# Inventory
func UseItem(itemID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var cell : ItemCell = DB.GetItem(itemID)
	if cell and cell.usable:
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.UseItem(cell)

func DropItem(itemID : int, customfield : StringName, itemCount : int, rpcID : int = NetworkCommons.RidSingleMode):
	var cell : ItemCell = DB.GetItem(itemID, customfield)
	if cell:
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.DropItem(cell, itemCount)

func EquipItem(itemID : int, customfield : StringName, rpcID : int = NetworkCommons.RidSingleMode):
	var cell : ItemCell = DB.GetItem(itemID, customfield)
	if cell and cell.slot != ActorCommons.Slot.NONE:
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.EquipItem(cell)

func UnequipItem(itemID : int, customfield : StringName, rpcID : int = NetworkCommons.RidSingleMode):
	var cell : ItemCell = DB.GetItem(itemID, customfield)
	if cell and cell.slot != ActorCommons.Slot.NONE:
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.UnequipItem(cell)

func PickupDrop(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		WorldDrop.PickupDrop(dropID, player)

func RetrieveCharacterInformation(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player and player.progress:
		Network.RefreshProgress(player.progress.skills, player.progress.quests, player.progress.bestiary, rpcID)
	if player and player.inventory:
		Network.RefreshInventory(player.inventory.ExportInventory(), rpcID)
	if player and player.stat:
		Network.UpdateAttributes(player.stat.strength, player.stat.vitality, player.stat.agility, player.stat.endurance, player.stat.concentration, rpcID)

# Peer handling
func ConnectPeer(rpcID : int):
	Util.PrintInfo("Server", "Peer connected: %d with %s" % [rpcID, "Websocket" if useWebSocket else "ENet"])
	Peers.AddPeer(rpcID, useWebSocket)
	bulks[rpcID] = {}
	if currentPeer and currentPeer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var clientPeer : PacketPeer = currentPeer.get_peer(rpcID)
		if clientPeer and clientPeer is ENetPacketPeer:
			clientPeer.set_timeout(NetworkCommons.Timeout, NetworkCommons.TimeoutMin, NetworkCommons.TimeoutMax)

func DisconnectPeer(rpcID : int):
	Util.PrintInfo("Server", "Peer disconnected: %d" % rpcID)
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		bulks.erase(rpcID)
		if peer.accountRID != NetworkCommons.RidUnknown:
			DisconnectAccount(rpcID)
		Peers.RemovePeer(rpcID)

#
func _enter_tree():
	if isOffline:
		uniqueID = NetworkCommons.RidSingleMode
		ConnectPeer(uniqueID)
		return

	if not multiplayerAPI.peer_connected.is_connected(ConnectPeer):
		multiplayerAPI.peer_connected.connect(ConnectPeer)
	if not multiplayerAPI.peer_disconnected.is_connected(DisconnectPeer):
		multiplayerAPI.peer_disconnected.connect(DisconnectPeer)

	var serverPort : int = NetworkCommons.WebSocketPort if useWebSocket else NetworkCommons.ENetPort
	if isTesting:
		serverPort = NetworkCommons.WebSocketPortTesting if useWebSocket else NetworkCommons.ENetPortTesting

	var tlsOptions : TLSOptions = null
	if ResourceLoader.exists(NetworkCommons.ServerCertPath) and ResourceLoader.exists(NetworkCommons.ServerKeyPath):
		var serverKey : CryptoKey = CryptoKey.new()
		var serverCert : X509Certificate = X509Certificate.new()
		serverKey.load(NetworkCommons.ServerKeyPath)
		serverCert.load(NetworkCommons.ServerCertPath)
		tlsOptions = TLSOptions.server(serverKey, serverCert)

	var ret : Error = FAILED
	if useWebSocket:
		ret = currentPeer.create_server(serverPort, "*", tlsOptions)
	else:
		ret = currentPeer.create_server(serverPort)
		if ret == OK and tlsOptions:
			ret = currentPeer.host.dtls_server_setup(tlsOptions)

	assert(ret == OK, "Server could not be created, please check if your port %d is valid" % serverPort)
	if ret == OK:
		multiplayerAPI.multiplayer_peer = currentPeer
		uniqueID = multiplayerAPI.get_unique_id()

		Util.PrintLog("Server", "Initialized with: %s, %s, %s, %s" % [
			"WebSocket" if useWebSocket else "ENet",
			"Offline" if isOffline else "Online",
			"Local" if isLocal else "Public",
			"Testing" if isTesting else "Release"
		])

func Destroy():
	if multiplayerAPI.peer_connected.is_connected(ConnectPeer):
		multiplayerAPI.peer_connected.disconnect(ConnectPeer)
	if multiplayerAPI.peer_disconnected.is_connected(DisconnectPeer):
		multiplayerAPI.peer_disconnected.disconnect(DisconnectPeer)

	for peerRID in Peers.peers:
		DisconnectPeer(peerRID)
	super.Destroy()
