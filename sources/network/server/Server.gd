extends NetInterface
class_name NetServer

# Auth
func CreateAccount(accountName : String, password : String, email : String, peerID : int):
	var err : NetworkCommons.AuthError = NetworkCommons.AuthError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(peerID)
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
	Network.AuthError(err, peerID)

func ConnectAccount(accountName : String, password : String, peerID : int):
	var err : NetworkCommons.AuthError = NetworkCommons.AuthError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(peerID)
	if not peer:
		err = NetworkCommons.AuthError.ERR_NO_PEER_DATA
	else:
		err = NetworkCommons.CheckAuthInformation(accountName, password)
		if err == NetworkCommons.AuthError.ERR_OK:
			peer.SetAccount(Launcher.SQL.Login(accountName, password))
			if peer.accountID == NetworkCommons.PeerUnknownID:
				err = NetworkCommons.AuthError.ERR_AUTH
			else:
				Launcher.SQL.UpdateAccount(peer.accountID)
	Network.AuthError(err, peerID)

func DisconnectAccount(peerID : int):
	var peer : Peers.Peer = Peers.GetPeer(peerID)
	if peer:
		if peer.accountID != NetworkCommons.PeerUnknownID:
			Launcher.SQL.UpdateAccount(peer.accountID)
			peer.SetAccount(Peers.DisconnectedAccount)
		if peer.characterID != NetworkCommons.PeerUnknownID:
			DisconnectCharacter(peerID)

# Character
func CreateCharacter(charName : String, traits : Dictionary, attributes : Dictionary, peerID : int):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var accountID : int = Peers.GetAccount(peerID)
	if accountID == NetworkCommons.PeerUnknownID:
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
			if characterID == NetworkCommons.PeerUnknownID:
				err = NetworkCommons.CharacterError.ERR_NO_CHARACTER_ID
			else:
				Network.characters_list_update.emit()
				for itemData in ActorCommons.DefaultInventory:
					Launcher.SQL.AddItem(characterID, itemData.get("item_id", DB.UnknownHash), itemData.get("customfield", ""), itemData.get("count", 1))
				for skillData in ActorCommons.DefaultSkills:
					Launcher.SQL.SetSkill(characterID, skillData.get("skill_id", DB.UnknownHash), skillData.get("level", 1))

				Network.CharacterInfo(Launcher.SQL.GetCharacterInfo(characterID), Launcher.SQL.GetEquipment(characterID), peerID)

	Network.CharacterError(err, peerID)
	return err

func DeleteCharacter(charName : String, peerID : int):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(peerID)
	if peer.accountID == NetworkCommons.PeerUnknownID:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	elif peer.characterID != NetworkCommons.PeerUnknownID:
		err = NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN
	else:
		var charID : int = Launcher.SQL.GetCharacterID(peer.accountID, charName)
		if charID == NetworkCommons.PeerUnknownID:
			err = NetworkCommons.CharacterError.ERR_NAME_VALID
		elif not Launcher.SQL.RemoveCharacter(charID):
			err = NetworkCommons.CharacterError.ERR_NAME_AVAILABLE
		else:
			Network.characters_list_update.emit()

	Network.CharacterError(err, peerID)
	return err


func ConnectCharacter(nickname : String, peerID : int):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(peerID)

	if not peer:
		err = NetworkCommons.CharacterError.ERR_NO_PEER_DATA
	elif peer.accountID == NetworkCommons.PeerUnknownID:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		if Peers.GetCharacter(peerID) != NetworkCommons.PeerUnknownID:
			err = NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN
		else:
			peer.SetCharacter(Launcher.SQL.GetCharacterID(peer.accountID, nickname))
			if peer.characterID == NetworkCommons.PeerUnknownID:
				err = NetworkCommons.CharacterError.ERR_NO_CHARACTER_ID
			else:
				var charInfo : Dictionary = Launcher.SQL.GetCharacterInfo(peer.characterID)
				var spawnLocation : SpawnObject = PlayerAgent.GetSpawnFromData(charInfo)
				var agent : PlayerAgent = WorldAgent.CreateAgent(spawnLocation, 0, nickname)
				if agent:
					agent.peerID = peerID
					peer.SetAgent(agent.get_rid().get_id())
					agent.SetCharacterInfo(charInfo, peer.characterID)
					Launcher.SQL.CharacterLogin(peer.characterID)
					Util.PrintLog("Server", "Player connected: %s (%d)" % [nickname, peerID])

	Network.CharacterError(err, peerID)

func DisconnectCharacter(peerID : int):
	var peer : Peers.Peer = Peers.GetPeer(peerID)
	if peer:
		var player : PlayerAgent = Peers.GetAgent(peerID)
		if player:
			Util.PrintLog("Server", "Player disconnected: %s (%d)" % [player.nick, peerID])
			Launcher.SQL.RefreshCharacter(player)
			WorldAgent.RemoveAgent(player)
			peer.SetAgent(NetworkCommons.PeerUnknownID)
		peer.SetCharacter(NetworkCommons.PeerUnknownID)

func CharacterListing(peerID : int):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var accountID : int = Peers.GetAccount(peerID)
	if accountID == NetworkCommons.PeerUnknownID:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		var characterIDs : PackedInt64Array = Launcher.SQL.GetCharacters(accountID)
		if characterIDs.is_empty():
			err = NetworkCommons.CharacterError.ERR_EMPTY_ACCOUNT
		else:
			for characterID in characterIDs:
				var charInfo : Dictionary = Launcher.SQL.GetCharacterInfo(characterID)
				var charEquipment : Dictionary = Launcher.SQL.GetEquipment(characterID)
				Network.CharacterInfo(charInfo, charEquipment, peerID)
	Network.CharacterError(err, peerID)

# Navigation
func SetClickPos(pos : Vector2, peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		player.SetRelativeMode(false, Vector2.ZERO)
		player.WalkToward(pos)

func SetMovePos(direction : Vector2, peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		player.SetRelativeMode(true, direction.normalized())

func ClearNavigation(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		player.SetRelativeMode(false, Vector2.ZERO)

# Triggers
func TriggerWarp(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player and player.ownScript == null:
		var warp : WarpObject = Launcher.World.CanWarp(player)
		if warp:
			var nextMap : WorldMap = Launcher.World.GetMap(warp.destinationID)
			if nextMap:
				Launcher.World.Warp(player, nextMap, warp.getDestinationPos(player))
				if warp is PortObject:
					player.Morph(false, player.GetNextPortShapeID())

func TriggerSit(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		player.SetState(ActorCommons.State.SIT)

func TriggerRespawn(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player is PlayerAgent:
		player.Respawn()

func TriggerEmote(emoteID : int, peerID : int):
	Network.NotifyNeighbours(Peers.GetAgent(peerID), "EmotePlayer", [emoteID])

func TriggerChat(text : String, peerID : int):
	Network.NotifyNeighbours(Peers.GetAgent(peerID), "ChatAgent", [text])

func TriggerChoice(choiceID : int, peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player and player.ownScript:
		player.ownScript.InteractChoice(choiceID)

func TriggerNextContext(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player and player.ownScript and player.ownScript.npc:
		player.ownScript.npc.Interact(player)

func TriggerCloseContext(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		NpcCommons.TryCloseContext(player)

func TriggerInteract(targetRID : int, peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		var target : BaseAgent = WorldAgent.GetAgent(targetRID)
		if target:
			target.Interact(player)

func TriggerExplore(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player is PlayerAgent:
		player.Explore()

func TriggerCast(targetRID : int, skillID : int, peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player and DB.SkillsDB.has(skillID):
		var target : BaseAgent = WorldAgent.GetAgent(targetRID)
		Skill.Cast(player, target, DB.SkillsDB[skillID])

func TriggerMorph(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if not player:
		return
	if player.stat.spirit == DB.UnknownHash:
		return
	var map : Object = WorldAgent.GetMapFromAgent(player)
	if map and map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
		return
	player.Morph(true)

func TriggerSelect(targetRID : int, peerID : int):
	var target : BaseAgent = WorldAgent.GetAgent(targetRID)
	if target:
		Network.UpdatePublicStats(targetRID, target.stat.level, target.stat.health, target.stat.hairstyle, target.stat.haircolor, target.stat.gender, target.stat.race, target.stat.skintone, target.stat.currentShape, peerID)

# Stats
func SetAttributes(strength, vitality, agility, endurance, concentration, peerID : int):
	var peer : Peers.Peer = Peers.GetPeer(peerID)
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if peer and peer.characterID != NetworkCommons.PeerUnknownID and player and player.stat:
		player.stat.SetAttributes(strength, vitality, agility, endurance, concentration)
		Launcher.SQL.UpdateAttribute(peer.characterID, player.stat)

# Inventory
func UseItem(itemID : int, peerID : int):
	var cell : ItemCell = DB.GetItem(itemID)
	if cell and cell.usable:
		var player : PlayerAgent = Peers.GetAgent(peerID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.UseItem(cell)

func DropItem(itemID : int, customfield : StringName, itemCount : int, peerID : int):
	var cell : ItemCell = DB.GetItem(itemID, customfield)
	if cell:
		var player : PlayerAgent = Peers.GetAgent(peerID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.DropItem(cell, itemCount)

func EquipItem(itemID : int, customfield : StringName, peerID : int):
	var cell : ItemCell = DB.GetItem(itemID, customfield)
	if cell and cell.slot != ActorCommons.Slot.NONE:
		var player : PlayerAgent = Peers.GetAgent(peerID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.EquipItem(cell)

func UnequipItem(itemID : int, customfield : StringName, peerID : int):
	var cell : ItemCell = DB.GetItem(itemID, customfield)
	if cell and cell.slot != ActorCommons.Slot.NONE:
		var player : PlayerAgent = Peers.GetAgent(peerID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.UnequipItem(cell)

func PickupDrop(dropID : int, peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		WorldDrop.PickupDrop(dropID, player)

func RetrieveCharacterInformation(peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player and player.progress:
		Network.RefreshProgress(player.progress.skills, player.progress.quests, player.progress.bestiary, peerID)
	if player and player.inventory:
		Network.RefreshInventory(player.inventory.ExportInventory(), peerID)
	if player and player.stat:
		Network.UpdateAttributes(player.stat.strength, player.stat.vitality, player.stat.agility, player.stat.endurance, player.stat.concentration, peerID)

# Commands
func TriggerCommand(command : String, peerID : int):
	var player : PlayerAgent = Peers.GetAgent(peerID)
	if player:
		CommandManager.Handle(player, command)

# Peer handling
func ConnectPeer(peerID : int):
	Util.PrintInfo("Server", "Peer connected: %d with %s" % [peerID, "Websocket" if useWebSocket else "ENet"])
	Peers.AddPeer(peerID, useWebSocket)
	bulks[peerID] = {}
	if currentPeer and currentPeer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var clientPeer : PacketPeer = currentPeer.get_peer(peerID)
		if clientPeer and clientPeer is ENetPacketPeer:
			clientPeer.set_timeout(NetworkCommons.Timeout, NetworkCommons.TimeoutMin, NetworkCommons.TimeoutMax)

func DisconnectPeer(peerID : int):
	Util.PrintInfo("Server", "Peer disconnected: %d" % peerID)
	var peer : Peers.Peer = Peers.GetPeer(peerID)
	if peer:
		bulks.erase(peerID)
		if peer.accountID != NetworkCommons.PeerUnknownID:
			DisconnectAccount(peerID)
		Peers.RemovePeer(peerID)

#
func _enter_tree():
	if isOffline:
		interfaceID = NetworkCommons.PeerAuthorityID
		ConnectPeer(interfaceID)
		return

	if not multiplayerAPI.peer_connected.is_connected(ConnectPeer):
		multiplayerAPI.peer_connected.connect(ConnectPeer)
	if not multiplayerAPI.peer_disconnected.is_connected(DisconnectPeer):
		multiplayerAPI.peer_disconnected.connect(DisconnectPeer)

	var serverPort : int = NetworkCommons.WebSocketPort if useWebSocket else NetworkCommons.ENetPort
	if LauncherCommons.IsTesting:
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
		interfaceID = multiplayerAPI.get_unique_id()

		Util.PrintLog("Server", "Initialized with: %s, %s, %s, %s" % [
			"WebSocket" if useWebSocket else "ENet",
			"Offline" if isOffline else "Online",
			"Local" if isLocal else "Public",
			"Testing" if LauncherCommons.IsTesting else "Release"
		])

func Destroy():
	if multiplayerAPI.peer_connected.is_connected(ConnectPeer):
		multiplayerAPI.peer_connected.disconnect(ConnectPeer)
	if multiplayerAPI.peer_disconnected.is_connected(DisconnectPeer):
		multiplayerAPI.peer_disconnected.disconnect(DisconnectPeer)

	for peerID in Peers.peers:
		DisconnectPeer(peerID)
	super.Destroy()
