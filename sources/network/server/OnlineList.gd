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

static func UpdateJson(players : PackedStringArray):
	if not NetworkCommons.OnlineListPath.is_empty():
		FileSystem.SaveFile(NetworkCommons.OnlineListPath + "/" + JSONFileName, JSON.stringify(players))

static func OnPlayerConnected(playerName : String):
	UpdateJson(GetPlayerNames())
	Network.NotifyGlobal("AddOnlinePlayer", [playerName])

static func OnPlayerDisconnected(playerName : String):
	UpdateJson(GetPlayerNames())
	Network.NotifyGlobal("RemoveOnlinePlayer", [playerName])
