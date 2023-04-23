extends Object
class_name OnlineList

var HTMLFileName : String				= "index.html"
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

func UpdateHtmlPageAndJson():
	var players : Array[String]	= GetPlayerNames()
	var content : String		= ""

	content += "<HTML>\n"
	content += "  <META http-equiv=\"Refresh\" content=\"%d\">\n" % 20
	content += "  <HEAD>\n"
	content += "    <TITLE>Online Players on %s</TITLE>\n" % "Source of Mana"
	content += "  </HEAD>\n"
	content += "  <BODY>\n"
	content += "    <H3>Online Players on %s (%s):</H3>\n" % ["Source of Mana", Time.get_datetime_string_from_system(true, true)]

	var playerCount : int = players.size()
	if playerCount > 0:
		content += "    <table border=\"1\" cellspacing=\"1\">\n"
		content += "      <tr>\n"
		content += "        <th>Name</th>\n"
		content += "      </tr>\n"

		for player in players:
			content += "      <tr>\n"
			content += "        <td>%s</th>\n" % str(player)
			content += "      </tr>\n"

	content += "    </table>\n"
	content += "    <p>%d users are online.</p>\n" % playerCount
	content += "    <p>If you look for a machine readable online list: <a href=\"./online.json\">online.json</a></p>\n"
	content += "  </BODY>\n"
	content += "</HTML>\n"

	Launcher.FileSystem.SaveFile(OS.get_executable_path().get_base_dir() + "/" + HTMLFileName, content)
	Launcher.FileSystem.SaveFile(OS.get_executable_path().get_base_dir() + "/" + JSONFileName, JSON.stringify(players))
