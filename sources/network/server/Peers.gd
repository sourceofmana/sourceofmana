extends Object
class_name Peers

#
class Peer:
	var accountRID : int				= NetworkCommons.RidUnknown
	var characterRID : int				= NetworkCommons.RidUnknown
	var agentRID : int					= NetworkCommons.RidUnknown
	var rpcDeltas : Dictionary			= {}

static var peers : Dictionary			= {}

# Handling
static func AddPeer(rpcID : int):
	if rpcID not in peers:
		peers[rpcID] = Peer.new()

static func RemovePeer(rpcID : int):
	peers.erase(rpcID)

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
static func GetPeer(rpcID : int) -> Peers.Peer:
	return Peers.peers[rpcID] if Peers and rpcID in Peers.peers else null

static func GetAccount(rpcID : int) -> int:
	var peer : Peers.Peer = GetPeer(rpcID)
	return peer.accountRID if peer else NetworkCommons.RidUnknown

static func GetCharacter(rpcID : int) -> int:
	var peer : Peers.Peer = GetPeer(rpcID)
	return peer.characterRID if peer else NetworkCommons.RidUnknown

static func GetAgent(rpcID : int) -> PlayerAgent:
	var peer : Peers.Peer = GetPeer(rpcID)
	return WorldAgent.GetAgent(peer.agentRID) if peer else null