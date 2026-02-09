extends RefCounted
class_name Peers

#
class Peer:
	var peerID : int								= NetworkCommons.PeerUnknownID
	var accountID : int								= NetworkCommons.PeerUnknownID
	var characterID : int							= NetworkCommons.PeerUnknownID
	var agentRID : int								= NetworkCommons.PeerUnknownID
	var permission : ActorCommons.Permission		= ActorCommons.Permission.NONE
	var usingWebSocket : bool						= false
	var rpcDeltas : Dictionary[StringName, int]		= {}

	func _init(_peerID : int, _usingWebSocket : bool):
		peerID = _peerID
		usingWebSocket = _usingWebSocket

	func SetAccount(id : int):
		if id != NetworkCommons.PeerUnknownID:
			var lastPeerID = Peers.accounts.get(id, NetworkCommons.PeerUnknownID)
			if lastPeerID != NetworkCommons.PeerUnknownID and Peers.GetAccount(lastPeerID) != NetworkCommons.PeerUnknownID:
				Network.DisconnectAccount(lastPeerID)
				Network.AuthError(NetworkCommons.AuthError.ERR_DUPLICATE_CONNECTION, lastPeerID)

		accountID = id
		Peers.accounts[id] = peerID
		Network.online_accounts_update.emit()
	func SetCharacter(id : int):
		characterID = id
		Network.online_characters_update.emit()
	func SetAgent(id : int):
		agentRID = id
		Network.online_agents_update.emit()

static var peers : Dictionary[int, Peer]			= {}
static var accounts : Dictionary[int, int]			= {}

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
	assert(peer, "Could not find data related to this peer: " + str(peerID))
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
