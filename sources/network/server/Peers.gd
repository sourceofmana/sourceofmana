extends Object
class_name Peers

#
class Peer:
	var peerRID : int								= NetworkCommons.RidUnknown
	var accountRID : int							= NetworkCommons.RidUnknown
	var characterRID : int							= NetworkCommons.RidUnknown
	var agentRID : int								= NetworkCommons.RidUnknown
	var usingWebSocket : bool						= false
	var rpcDeltas : Dictionary[String, int]			= {}

	func _init(_rpcID : int, _usingWebSocket : bool):
		peerRID = _rpcID
		usingWebSocket = _usingWebSocket

	func SetAccount(id : int):
		if id != NetworkCommons.RidUnknown:
			var lastPeerRID = Peers.accounts.get(id, NetworkCommons.RidUnknown)
			if lastPeerRID != NetworkCommons.RidUnknown and Peers.GetAccount(lastPeerRID) != NetworkCommons.RidUnknown:
				Network.DisconnectAccount(lastPeerRID)
				Network.AuthError(NetworkCommons.AuthError.ERR_DUPLICATE_CONNECTION, lastPeerRID)

		accountRID = id
		Peers.accounts[id] = peerRID
		Network.online_accounts_update.emit()
	func SetCharacter(id : int):
		characterRID = id
		Network.online_characters_update.emit()
	func SetAgent(id : int):
		agentRID = id
		Network.online_agents_update.emit()

static var peers : Dictionary[int, Peer]			= {}
static var accounts : Dictionary[int, int]			= {}

# Handling
static func AddPeer(rpcID : int, usingWebSocket : bool):
	if rpcID not in peers:
		peers[rpcID] = Peer.new(rpcID, usingWebSocket)
		Network.peer_update.emit()

static func RemovePeer(rpcID : int):
	var peer : Peers.Peer = GetPeer(rpcID)
	if peer:
		peers.erase(rpcID)
		Network.peer_update.emit()

static func Footprint(rpcID : int, methodName : String, actionDelta : int) -> bool:
	var peer : Peers.Peer = GetPeer(rpcID)
	assert(peer, "Could not find data related to this peer: " + str(rpcID))
	if peer:
		var oldTick : int = 0
		if methodName in peers[rpcID].rpcDeltas:
			oldTick = peers[rpcID].rpcDeltas[methodName]

		var currentTick : int = Time.get_ticks_msec()
		if oldTick + actionDelta <= currentTick:
			peers[rpcID].rpcDeltas[methodName] = currentTick
			return true

	return false

static func IsUsingWebSocket(rpcID : int) -> bool:
	var peer : Peers.Peer = GetPeer(rpcID)
	return peer.usingWebSocket if peer else false

# Info getters
static func HasPeer(rpcID : int) -> bool:
	return rpcID in Peers.peers

static func GetPeer(rpcID : int) -> Peers.Peer:
	return Peers.peers.get(rpcID, null)

static func GetAccount(rpcID : int) -> int:
	var peer : Peers.Peer = GetPeer(rpcID)
	return peer.accountRID if peer else NetworkCommons.RidUnknown

static func GetCharacter(rpcID : int) -> int:
	var peer : Peers.Peer = GetPeer(rpcID)
	return peer.characterRID if peer else NetworkCommons.RidUnknown

static func GetAgent(rpcID : int) -> PlayerAgent:
	var peer : Peers.Peer = GetPeer(rpcID)
	return WorldAgent.GetAgent(peer.agentRID) if peer else null
