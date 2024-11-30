extends Object

# Auth
func CreateAccount(accountName : String, password : String, email : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(accountName, password)
	if err == NetworkCommons.AuthError.ERR_OK:
		if not Launcher.SQL.AddAccount(accountName, password, email):
			err = NetworkCommons.AuthError.ERR_NAME_AVAILABLE
	Launcher.Network.AuthError(err, rpcID)

func ConnectAccount(accountName : String, password : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.AuthError = NetworkCommons.AuthError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if not peer:
		err = NetworkCommons.AuthError.ERR_NO_PEER_DATA
	else:
		err = NetworkCommons.CheckAuthInformation(accountName, password)
		if err == NetworkCommons.AuthError.ERR_OK:
			peer.accountRID = Launcher.SQL.Login(accountName, password)

			# Remove once account creation logic is implemented
			if peer.accountRID == NetworkCommons.RidUnknown:
				if not Launcher.SQL.AddAccount(accountName, password, "g@g.g"):
					err = NetworkCommons.AuthError.ERR_NAME_AVAILABLE
				else:
					peer.accountRID = Launcher.SQL.Login(accountName, password)
			# -- end

			if peer.accountRID == NetworkCommons.RidUnknown:
				err = NetworkCommons.AuthError.ERR_AUTH
			else:
				for characterID in Launcher.SQL.GetCharacters(peer.accountRID):
					var characterInfo : Dictionary = Launcher.SQL.GetCharacterInfo(characterID)
					Launcher.Network.CharacterInfo(characterInfo, rpcID) # To send every character info 1 by 1
	Launcher.Network.AuthError(err, rpcID)

func DisconnectAccount(rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		peer.accountRID = NetworkCommons.RidUnknown
		if peer.characterRID != NetworkCommons.RidUnknown:
			DisconnectCharacter(rpcID)

# Character
func CreateCharacter(charName : String, traits : Dictionary, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var accountID : int = Peers.GetAccount(rpcID)
	if accountID == NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		if not Launcher.SQL.AddCharacter(accountID, charName, traits):
			err = NetworkCommons.CharacterError.ERR_NAME_AVAILABLE
		else:
			var characterID : int = Launcher.SQL.GetCharacterID(accountID, charName)
			if characterID == NetworkCommons.RidUnknown:
				err = NetworkCommons.CharacterError.ERR_NO_CHARACTER_ID
			else:
				Launcher.Network.CharacterInfo(Launcher.SQL.GetCharacterInfo(characterID), rpcID)

	Launcher.Network.CharacterError(err)
	return err

func ConnectCharacter(nickname : String, rpcID : int = NetworkCommons.RidSingleMode):
	var err : NetworkCommons.CharacterError = NetworkCommons.CharacterError.ERR_OK
	var peer : Peers.Peer = Peers.GetPeer(rpcID)

	if not peer:
		err = NetworkCommons.CharacterError.ERR_NO_PEER_DATA
	elif peer.accountRID == NetworkCommons.RidUnknown:
		err = NetworkCommons.CharacterError.ERR_NO_ACCOUNT_ID
	else:
		peer.characterRID = Launcher.SQL.GetCharacterID(peer.accountRID, nickname)
		if peer.characterRID == NetworkCommons.RidUnknown:
			err = NetworkCommons.CharacterError.ERR_NO_CHARACTER_ID
		else:
			if Peers.GetAgent(rpcID):
				err = NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN
			else:
				var agent : PlayerAgent = WorldAgent.CreateAgent(Launcher.World.defaultSpawn, 0, nickname)
				if agent:
					peer.agentRID = agent.get_rid().get_id()
					agent.stat.SetAttributes(ActorCommons.DefaultAttributes)
					agent.inventory.ImportInventory(ActorCommons.DefaultInventory)
					agent.rpcRID = rpcID
					OnlineList.UpdateJson()
					Util.PrintLog("Server", "Player connected: %s (%d)" % [nickname, rpcID])

	Launcher.Network.CharacterError(err, rpcID)

func DisconnectCharacter(rpcID : int = NetworkCommons.RidSingleMode):
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		peer.characterRID = NetworkCommons.RidUnknown
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		if player:
			Util.PrintLog("Server", "Player disconnected: %s (%d)" % [player.get_name(), rpcID])
			WorldAgent.RemoveAgent(player)
			peer.characterRID = NetworkCommons.RidUnknown
			peer.agentRID = NetworkCommons.RidUnknown
			OnlineList.UpdateJson()

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
		if player.stat.spiritShape.length() == 0:
			return
		var map : Object = WorldAgent.GetMapFromAgent(player)
		if map and map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
			return

		player.Morph(true)

func TriggerSelect(targetID : int, rpcID : int = NetworkCommons.RidSingleMode):
	var target : BaseAgent = WorldAgent.GetAgent(targetID)
	if target:
		Launcher.Network.UpdateAttributes(targetID, target.stat.strength, target.stat.vitality, target.stat.agility, target.stat.endurance, target.stat.concentration, rpcID)
		Launcher.Network.UpdateActiveStats(targetID, target.stat.level, target.stat.experience, target.stat.gp, target.stat.health, target.stat.mana, target.stat.stamina, target.stat.weight, target.stat.entityShape, target.stat.spiritShape, target.stat.currentShape, rpcID)

# Stats
func AddAttribute(attribute : ActorCommons.Attribute, rpcID : int = NetworkCommons.RidSingleMode):
	var player : PlayerAgent = Peers.GetAgent(rpcID)
	if player and player.stat:
		player.stat.AddAttribute(attribute)

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
		Launcher.Network.RefreshInventory(player.inventory.ExportInventory(), rpcID)

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
		Launcher.Network.callv(callbackName, [currentAgentID] + args + [agent.rpcRID])

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	if inst:
		for player in inst.players:
			if player != null and player != agent and player.rpcRID != NetworkCommons.RidUnknown:
				Launcher.Network.callv(callbackName, [currentAgentID] + args + [player.rpcRID])

func NotifyInstance(inst : WorldInstance, callbackName : String, args : Array):
	if inst:
		for player in inst.players:
			if player != null:
				if player.rpcRID != NetworkCommons.RidUnknown:
					Launcher.Network.callv(callbackName, args + [player.rpcRID])

# Peer handling
func ConnectPeer(rpcID : int):
	Util.PrintInfo("Server", "Peer connected: %d" % rpcID)
	Peers.AddPeer(rpcID)
	if Launcher.Network.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var clientPeer : PacketPeer = Launcher.Network.peer.get_peer(rpcID)
		if clientPeer and clientPeer is ENetPacketPeer:
			clientPeer.set_timeout(NetworkCommons.Timeout, NetworkCommons.TimeoutMin, NetworkCommons.TimeoutMax)

func DisconnectPeer(rpcID : int):
	Util.PrintInfo("Server", "Peer disconnected: %d" % rpcID)
	var peer : Peers.Peer = Peers.GetPeer(rpcID)
	if peer:
		if peer.accountRID != NetworkCommons.RidUnknown:
			DisconnectAccount(rpcID)
		Peers.RemovePeer(rpcID)

func Destroy():
	for peerRID in Peers.peers:
		DisconnectPeer(peerRID)
