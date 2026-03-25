extends RefCounted
class_name Peers

#
static var DisconnectedAccount : AccountData = AccountData.new(NetworkCommons.PeerUnknownID, ActorCommons.Permission.NONE)

#
class AccountData:
	extends RefCounted

	var accountID : int								= NetworkCommons.PeerUnknownID
	var permission : ActorCommons.Permission		= ActorCommons.Permission.NONE

	func _init(id : int, newPermission : ActorCommons.Permission):
		accountID = id
		permission = newPermission

class Peer:
	extends RefCounted

	var accountID : int								= NetworkCommons.PeerUnknownID
	var peerID : int								= NetworkCommons.PeerUnknownID
	var characterID : int							= NetworkCommons.PeerUnknownID
	var agentRID : int								= NetworkCommons.PeerUnknownID
	var permission : ActorCommons.Permission		= ActorCommons.Permission.NONE
	var accountData : AccountData					= null
	var usingWebSocket : bool						= false
	var rpcDeltas : Dictionary[StringName, int]		= {}

	func _init(id : int, useWebSocket : bool):
		peerID = id
		usingWebSocket = useWebSocket

	func SetAccount(data : AccountData):
		if data and data.accountID != NetworkCommons.PeerUnknownID:
			var lastPeerID = Peers.accounts.get(data.accountID, NetworkCommons.PeerUnknownID)
			if lastPeerID != NetworkCommons.PeerUnknownID and Peers.GetAccount(lastPeerID) != NetworkCommons.PeerUnknownID:
				Network.DisconnectAccount(lastPeerID)
				if data.accountID == lastPeerID:
					Network.AuthError(NetworkCommons.AuthError.ERR_DUPLICATE_CONNECTION, lastPeerID)
			Peers.accounts[data.accountID] = NetworkCommons.PeerUnknownID
		if data:
			Peers.accounts[data.accountID] = peerID
			accountID = data.accountID
			permission = data.permission
		Network.online_accounts_update.emit()

	func SetCharacter(id : int):
		characterID = id
		Network.online_characters_update.emit()

	func SetAgent(id : int):
		agentRID = id
		Network.online_agents_update.emit()

static var peers : Dictionary[int, Peer]			= {}
static var accounts : Dictionary[int, int]			= {}
static var bannedAccounts : Dictionary[int, int]	= {}

# Moderation
static func IsBanned(accountID : int) -> bool:
	var unbanTimestamp : int = bannedAccounts.get(accountID, 0)
	if unbanTimestamp > 0:
		if unbanTimestamp > int(Time.get_unix_time_from_system()):
			return true
		bannedAccounts.erase(accountID)
	return false

# Handling
static func AddPeer(peerID : int, usingWebSocket : bool):
	if peerID not in peers:
		peers[peerID] = Peer.new(peerID, usingWebSocket)
		Network.peer_update.emit()

static func RemovePeer(peerID : int):
	var peer : Peers.Peer = GetPeer(peerID)
	if peer:
		peers.erase(peerID)
		Network.peer_update.emit()

static func Footprint(peerID : int, methodName : StringName, actionDelta : int) -> bool:
	var peer : Peers.Peer = GetPeer(peerID)
	if peer:
		var oldTick : int = 0
		if methodName in peers[peerID].rpcDeltas:
			oldTick = peers[peerID].rpcDeltas[methodName]

		var currentTick : int = Time.get_ticks_msec()
		if oldTick + actionDelta <= currentTick:
			peers[peerID].rpcDeltas[methodName] = currentTick
			return true

	return false

static func IsUsingWebSocket(peerID : int) -> bool:
	var peer : Peers.Peer = GetPeer(peerID)
	return peer.usingWebSocket if peer else false

static func GetAssociatedNetServer(peerID : int) -> NetServer:
	if HasPeer(peerID):
		return Network.WebSocketServer if IsUsingWebSocket(peerID) else Network.ENetServer
	return null

static func GetPeerIP(peerID : int) -> String:
	var peer : Peers.Peer = GetPeer(peerID)
	if peer:
		if peer.usingWebSocket and Network.WebSocketServer and not Network.WebSocketServer.isOffline:
			var packetPeer : PacketPeer = Network.WebSocketServer.currentPeer.get_peer(peerID)
			if packetPeer and packetPeer is WebSocketPeer:
				return packetPeer.get_connected_host()
		elif Network.ENetServer and not Network.ENetServer.isOffline:
			var packetPeer : PacketPeer = Network.ENetServer.currentPeer.get_peer(peerID)
			if packetPeer and packetPeer is ENetPacketPeer:
				return packetPeer.get_remote_address()
		else:
			return NetworkCommons.LocalServerAddress
	return ""

# Info getters
static func HasPeer(peerID : int) -> bool:
	return peerID in Peers.peers

static func GetPeer(peerID : int) -> Peers.Peer:
	return Peers.peers.get(peerID, null)

static func GetAccount(peerID : int) -> int:
	var peer : Peers.Peer = GetPeer(peerID)
	return peer.accountID if peer else NetworkCommons.PeerUnknownID

static func GetCharacter(peerID : int) -> int:
	var peer : Peers.Peer = GetPeer(peerID)
	return peer.characterID if peer else NetworkCommons.PeerUnknownID

static func GetAgent(peerID : int) -> PlayerAgent:
	var peer : Peers.Peer = GetPeer(peerID)
	return WorldAgent.GetAgent(peer.agentRID) if peer else null

static func GetPermission(peerID : int) -> ActorCommons.Permission:
	var peer : Peers.Peer = GetPeer(peerID)
	return peer.permission if peer else ActorCommons.Permission.NONE

# Auth validation
static func FinalizeLogin(peer : Peer, accountName : String, accountData : AccountData, rememberMe : bool = false) -> NetworkCommons.AuthError:
	if IsBanned(accountData.accountID):
		return NetworkCommons.AuthError.ERR_BANNED

	peer.SetAccount(accountData)
	Launcher.SQL.UpdateAccount(peer.accountID)

	if rememberMe:
		IssueAuthToken(peer, accountName)

	return NetworkCommons.AuthError.ERR_OK

static func IssueAuthToken(peer : Peer, accountName : String) -> void:
	var ipAddress : String = GetPeerIP(peer.peerID)
	var token : String = Hasher.GenerateSalt(Hasher.DefaultTokenSize)
	var tokenHash : String = Hasher.HashPassword(token)
	Launcher.SQL.AddAuthToken(peer.accountID, tokenHash, ipAddress)
	Network.AuthTokenResult(accountName, token, peer.peerID)
