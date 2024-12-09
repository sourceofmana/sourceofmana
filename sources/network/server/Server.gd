extends Object

#
signal peer_update
signal accounts_list_update
signal characters_list_update
signal online_accounts_update
signal online_characters_update
signal online_agents_update

# Auth
func CreateAccount(accountName : String, password : String, email : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.AuthError = NetworkCommons.AuthError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if not peer:
		err = NetworkCommons.AuthError.ERR_NO_PEER_DATA
	else:
		err = NetworkCommons.CheckAuthInformation(accountName, password)
		if err == NetworkCommons.AuthError.ERR_OK:
			if not Launcher.SQL.AddAccount(accountName, password, email):
				err = NetworkCommons.AuthError.ERR_NAME_AVAILABLE
			else:
				accounts_list_update.emit()
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
	Network.AuthError(err, rpcID)

func DisconnectAccount(rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
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
		if Launcher.SQL.GetCharacters(accountID).size() >= ActorCommons.MaxCharacterCount:
			err = NetworkCommons.CharacterError.ERR_SLOT_AVAILABLE
		if not Launcher.SQL.AddCharacter(accountID, charName, traits, attributes):
			err = NetworkCommons.CharacterError.ERR_NAME_AVAILABLE
		else:
			var characterID : int = Launcher.SQL.GetCharacterID(accountID, charName)
			if characterID == NetworkCommons.RidUnknown:
				err = NetworkCommons.CharacterError.ERR_NO_CHARACTER_ID
			else:
				characters_list_update.emit()
				Network.CharacterInfo(Launcher.SQL.GetCharacterInfo(characterID), rpcID)

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
				var agent : PlayerAgent = WorldAgent.CreateAgent(Launcher.World.defaultSpawn, 0, nickname)
				if agent:
					var info : Dictionary = Launcher.SQL.GetCharacterInfo(peer.characterRID)
					peer.SetAgent(agent.get_rid().get_id())
					agent.stat.SetAttributes(info)
					agent.inventory.ImportInventory(ActorCommons.DefaultInventory)
					agent.rpcRID = rpcID
					Util.PrintLog("Server", "Player connected: %s (%d)" % [nickname, rpcID])

	Network.CharacterError(err, rpcID)

func DisconnectCharacter(rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		peer.SetCharacter(NetworkCommons.RidUnknown)
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player:
			Util.PrintLog("Server", "Player disconnected: %s (%d)" % [player.get_name(), rpcID])
			WorldAgent.RemoveAgent(player)
			peer.SetAgent(NetworkCommons.RidUnknown)

func CharacterListing(rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var accountID : int = Peers.GetAccount(rpcID)
	if accountID == NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		for characterID in Launcher.SQL.GetCharacters(accountID):
			var characterInfo : Dictionary = Launcher.SQL.GetCharacterInfo(characterID)
			Network.CharacterInfo(characterInfo, rpcID)
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
			var nextMap : WorldMap = Launcher.World.GetMap(warp.destinationMap)
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
	NotifyNeighbours(Peers.GetAgent(rpcID), "EmotePlayer", [emoteID])

func TriggerChat(text : String, rpcID : int = NetworkCommons.RidSingleMode):
	NotifyNeighbours(Peers.GetAgent(rpcID), "ChatAgent", [text])

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
	if player:
		if player.stat.spirit.length() == 0:
			return
		var map : Object = WorldAgent.GetMapFromAgent(player)
		if map and map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
			return

		player.Morph(true)

func TriggerSelect(targetID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var target : BaseAgent = WorldAgent.GetAgent(targetID)
	if target:
		Network.UpdateAttributes(targetID, target.stat.strength, target.stat.vitality, target.stat.agility, target.stat.endurance, target.stat.concentration, rpcID)
		Network.UpdateActiveStats(targetID, target.stat.level, target.stat.experience, target.stat.gp, target.stat.health, target.stat.mana, target.stat.stamina, target.stat.weight, target.stat.shape, target.stat.spirit, target.stat.currentShape, rpcID)

# Stats
func AddAttribute(attribute : ActorCommons.Attribute, rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if peer and peer.characterRID != NetworkCommons.RidUnknown and player and player.stat:
		player.stat.AddAttribute(attribute)
		Launcher.SQL.UpdateAttribute(peer.characterRID, player.stat)

# Inventory
func UseItem(itemID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var cell : BaseCell = DB.ItemsDB[itemID] if DB.ItemsDB.has(itemID) else null
	if cell and cell.usable:
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player and ActorCommons.IsAlive(player) and player.inventory:
			player.inventory.UseItem(cell)

func RetrieveInventory(rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player and player.inventory:
		Network.RefreshInventory(player.inventory.ExportInventory(), rpcID)

func PickupDrop(dropID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player:
		WorldDrop.PickupDrop(dropID, player)

# Notify
func NotifyNeighbours(agent : BaseAgent, callbackName : String, args : Array, inclusive : bool = true):
	if not agent:
		assert(false, "Agent is misintantiated, could not notify instance players with " + callbackName)
		return

	var currentAgentID = agent.get_rid().get_id()
	if inclusive and agent is PlayerAgent:
		Network.callv(callbackName, [currentAgentID] + args + [agent.rpcRID])

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	if inst:
		for player in inst.players:
			if player != null and player != agent and player.rpcRID != NetworkCommons.RidUnknown:
				Network.callv(callbackName, [currentAgentID] + args + [player.rpcRID])

func NotifyInstance(inst : WorldInstance, callbackName : String, args : Array):
	if inst:
		for player in inst.players:
			if player != null:
				if player.rpcRID != NetworkCommons.RidUnknown:
					Network.callv(callbackName, args + [player.rpcRID])

# Peer handling
func ConnectPeer(rpcID : int):
	Util.PrintInfo("Server", "Peer connected: %d" % rpcID)
	Peers.AddPeer(rpcID)
	if Network.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var clientPeer : PacketPeer = Network.peer.get_peer(rpcID)
		if clientPeer and clientPeer is ENetPacketPeer:
			clientPeer.set_timeout(NetworkCommons.Timeout, NetworkCommons.TimeoutMin, NetworkCommons.TimeoutMax)

func DisconnectPeer(rpcID : int):
	Util.PrintInfo("Server", "Peer disconnected: %d" % rpcID)
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		if peer.accountRID != NetworkCommons.RidUnknown:
			DisconnectAccount(rpcID)
		Peers.RemovePeer(rpcID)

#
func Init():
	if not online_agents_update.is_connected(OnlineList.UpdateJson):
		online_agents_update.connect(OnlineList.UpdateJson)
	if not Launcher.Root.multiplayer.peer_connected.is_connected(ConnectPeer):
		Launcher.Root.multiplayer.peer_connected.connect(ConnectPeer)
	if not Launcher.Root.multiplayer.peer_disconnected.is_connected(DisconnectPeer):
		Launcher.Root.multiplayer.peer_disconnected.connect(DisconnectPeer)

	Util.PrintLog("Server", "Initialized on port %d" % NetworkCommons.ServerPort)

func Destroy():
	if online_agents_update.is_connected(OnlineList.UpdateJson):
		online_agents_update.disconnect(OnlineList.UpdateJson)
	if Launcher.Root.multiplayer.peer_connected.is_connected(ConnectPeer):
		Launcher.Root.multiplayer.peer_connected.disconnect(ConnectPeer)
	if Launcher.Root.multiplayer.peer_disconnected.is_connected(DisconnectPeer):
		Launcher.Root.multiplayer.peer_disconnected.disconnect(DisconnectPeer)

	for peerRID in Peers.peers:
		DisconnectPeer(peerRID)
