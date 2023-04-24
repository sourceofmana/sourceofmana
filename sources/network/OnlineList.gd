extends Object
class_name OnlineList

var JSONFileName : String				= "online.json"

#
func GetPlayerNames() -> Array[String]:
	var players : Array[String] = []
	if Launcher.World and Launcher.Network.Server:
		for playerID in Launcher.Network.Server.playerMap.values():
			var agent : PlayerAgent = Launcher.World.GetAgent(playerID)
			if agent:
				players.append(agent.agentName)
	return players

func UpdateJson():
	var players : Array[String]	= GetPlayerNames()
	Launcher.FileSystem.SaveFile(OS.get_executable_path().get_base_dir() + "/" + JSONFileName, JSON.stringify(players))
