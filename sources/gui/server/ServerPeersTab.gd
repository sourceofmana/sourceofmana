extends ServerTab

#
@onready var label : RichTextLabel			= $RichTextLabel

#
func Refresh():
	var lines : PackedStringArray = []
	for peerID in Peers.peers:
		var peer : Peers.Peer = Peers.GetPeer(peerID)
		var player : PlayerAgent = Peers.GetAgent(peerID)
		var playerNickname : String = player.nick if player else "-1"
		lines.append("RPC: %d\t\tAccount: %d\t\tCharacter: %d\t\tAgent: %s [%d]\t\tMode: %s" % [peerID, peer.accountID, peer.characterID, playerNickname, peer.agentRID, Peers.GetTransportName(peer.transport)])
	var text : String = "\n".join(lines)
	if label.text != text:
		label.text = text
