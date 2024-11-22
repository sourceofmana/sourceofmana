extends Object
class_name OnlineList

#
const JSONFileName : String				= "online.json"

#
static func GetPlayerNames() -> Array[String]:
	var players : Array[String] = []
	for peerID in Peers.peers:
		var agent : PlayerAgent = Peers.GetAgent(peerID)
		if agent:
			players.append(agent.nick)
	return players

static func UpdateJson():
	var players : Array[String]	= GetPlayerNames()
	FileSystem.SaveFile(OS.get_executable_path().get_base_dir() + "/" + JSONFileName, JSON.stringify(players))
