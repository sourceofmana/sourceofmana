extends ServerTableTab

#
const ListSize : int						= 25
const Header : PackedStringArray			= ["Character", "Account", "Level", "Exp", "Quests", "Kills", "GP", "Play time", "Map", "Created", "Last seen"]

#
func FillCharacters(title : String, entries : Array[Dictionary]):
	var rows : Array = []
	for entry in entries:
		var mapData : MapData = DB.MapsDB.get(entry.pos_map, null)
		rows.append([
			entry.nickname,
			entry.username,
			entry.level,
			entry.experience,
			entry.quests,
			entry.kills,
			entry.gp,
			Util.FormatPlayTime(entry.play_time),
			mapData._name if mapData else "-",
			Util.FormatDate(entry.created_timestamp),
			"Online" if entry.online else Util.FormatTimeAgo(entry.last_timestamp),
		])

	var table : TableView = FillTable(title, Header, rows)
	for rowIndex in entries.size():
		if entries[rowIndex].online:
			table.SetCellColor(rowIndex, Header.size() - 1, UICommons.ModifierPositiveColor)

#
func Refresh():
	FillCharacters("Last active characters", SQLStats.GetLastActiveCharacters(ListSize))
	FillCharacters("Latest characters created", SQLStats.GetLatestCharacters(ListSize))
