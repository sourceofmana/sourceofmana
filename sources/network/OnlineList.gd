extends Object
class_name OnlineList

var JSONFileName : String				= "online.json"

#
func GetPlayerNames() -> Array[String]:
	var players : Array[String] = []
	if Launcher.Network and Launcher.Network.Server:
		for peerID in Launcher.Network.Server.peers.keys():
			var agent : PlayerAgent = Launcher.Network.Server.GetAgent(peerID)
			if agent:
				players.append(agent.nick)
	return players

func UpdateJson():
	var players : Array[String]	= GetPlayerNames()
	FileSystem.SaveFile(OS.get_executable_path().get_base_dir() + "/" + JSONFileName, JSON.stringify(players))
