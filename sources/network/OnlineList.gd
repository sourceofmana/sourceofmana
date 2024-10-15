extends Object
class_name OnlineList

var JSONFileName : String				= "online.json"

#
func GetPlayerNames() -> Array[String]:
	var players : Array[String] = []
	if Launcher.Network.Server:
		for playerData in Launcher.Network.Server.playerMap.values():
			var agent : PlayerAgent = WorldAgent.GetAgent(playerData.agentRID)
			if agent:
				players.append(agent.nick)
	return players

func UpdateJson():
	var players : Array[String]	= GetPlayerNames()
	FileSystem.SaveFile(OS.get_executable_path().get_base_dir() + "/" + JSONFileName, JSON.stringify(players))
