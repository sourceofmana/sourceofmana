extends RefCounted
class_name OnlineList

#
const JSONFileName : String				= "online.json"

#
static func GetPlayerNames() -> PackedStringArray:
	var players : Array[String] = []
	for peerID in Peers.peers:
		var agent : PlayerAgent = Peers.GetAgent(peerID)
		if agent:
			players.append(agent.nick)
	return players

static func UpdateJson():
	var players : PackedStringArray	= GetPlayerNames()
	FileSystem.SaveFile(NetworkCommons.OnlineListPath + "/" + JSONFileName, JSON.stringify(players))
