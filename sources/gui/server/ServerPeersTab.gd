extends ServerTableTab

#
const Header : PackedStringArray			= ["RPC", "Account", "Character", "Agent", "Agent RID", "Mode"]

#
func CanRefresh() -> bool:
	return true

func Refresh():
	var rows : Array = []
	for peerID in Peers.peers:
		var peer : Peers.Peer = Peers.GetPeer(peerID)
		var player : PlayerAgent = Peers.GetAgent(peerID)
		rows.append([
			peerID,
			peer.accountID,
			peer.characterID,
			player.nick if player else "-",
			peer.agentRID,
			Peers.GetTransportName(peer.transport),
		])
	FillTable("Connected peers", Header, rows)

#
func _init():
	super._init()
	refreshTicks = 1
