extends Object
class_name Peers

#
class Peer:
	var peerRID : int								= NetworkCommons.RidUnknown
	var accountRID : int							= NetworkCommons.RidUnknown
	var characterRID : int							= NetworkCommons.RidUnknown
	var agentRID : int								= NetworkCommons.RidUnknown
	var rpcDeltas : Dictionary[String, int]			= {}

	func _init(rpcID : int):
		peerRID = rpcID

	func SetAccount(id : int):
		if id != NetworkCommons.RidUnknown:
			var lastPeerRID = Peers.accounts.get(id, NetworkCommons.RidUnknown)
			if lastPeerRID != NetworkCommons.RidUnknown and Peers.GetAccount(lastPeerRID) != NetworkCommons.RidUnknown:
				Network.Server.DisconnectAccount(lastPeerRID)
				Network.AuthError(NetworkCommons.AuthError.ERR_DUPLICATE_CONNECTION, lastPeerRID)

		accountRID = id
		Peers.accounts[id] = peerRID
		Network.Server.online_accounts_update.emit()
	func SetCharacter(id : int):
		characterRID = id
		Network.Server.online_characters_update.emit()
	func SetAgent(id : int):
		agentRID = id
		Network.Server.online_agents_update.emit()

static var peers : Dictionary[int, Peer]			= {}
static var accounts : Dictionary[int, int]			= {}

# Handling
static func AddPeer(rpcID : int):
	if rpcID not in peers:
		peers[rpcID] = Peer.new(rpcID)
		if Network.Server:
			Network.Server.peer_update.emit()

static func RemovePeer(rpcID : int):
	if peers.erase(rpcID):
		if Network.Server:
			Network.Server.peer_update.emit()

static func Footprint(rpcID : int, methodName : String, actionDelta : int) -> bool:
	assert(rpcID in peers, "Could not find data related to this peer: " + str(rpcID))
	if rpcID in peers:
		var oldTick : int = 0
		if methodName in peers[rpcID].rpcDeltas:
			oldTick = peers[rpcID].rpcDeltas[methodName]

		var currentTick : int = Time.get_ticks_msec()
		if oldTick + actionDelta <= currentTick:
			peers[rpcID].rpcDeltas[methodName] = currentTick
			return true

	return false

# Info getters
static func HasPeer(rpcID : int) -> bool:
	return rpcID in Peers.peers

static func GetPeer(rpcID : int) -> Peers.Peer:
	return Peers.peers.get(rpcID)

static func GetAccount(rpcID : int) -> int:
	var peer : Peers.Peer = GetPeer(rpcID)
	return peer.accountRID if peer else NetworkCommons.RidUnknown

static func GetCharacter(rpcID : int) -> int:
	var peer : Peers.Peer = GetPeer(rpcID)
	return peer.characterRID if peer else NetworkCommons.RidUnknown

static func GetAgent(rpcID : int) -> PlayerAgent:
	var peer : Peers.Peer = GetPeer(rpcID)
	return WorldAgent.GetAgent(peer.agentRID) if peer else null
