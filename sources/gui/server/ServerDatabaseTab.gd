extends ServerTableTab

#
const PeriodNames : Dictionary[SQLStats.Period, String] = {
	SQLStats.Period.DAY: "Last 24h",
	SQLStats.Period.WEEK: "Last 7d",
	SQLStats.Period.MONTH: "Last 30d",
}

const ActivityNames : Dictionary[SQLStats.Activity, String] = {
	SQLStats.Activity.ACCOUNTS_CREATED: "Accounts created",
	SQLStats.Activity.ACCOUNTS_ACTIVE: "Accounts active",
	SQLStats.Activity.CHARACTERS_CREATED: "Characters created",
	SQLStats.Activity.CHARACTERS_ACTIVE: "Characters active",
}

const LatestAccountsSize : int				= 25
var pathLabel : Label						= null

#
func RefreshPath(queryFailed : bool):
	if not pathLabel:
		pathLabel = AddLabel("")
	var dbPath : String = SQLCommons.GetDBPath()
	var file : FileAccess = FileAccess.open(dbPath, FileAccess.READ)
	var sizeMB : float = file.get_length() / 1000000.0 if file else 0.0
	pathLabel.text = "Database: %s (%.2f MB)%s" % [ProjectSettings.globalize_path(dbPath), sizeMB, " - could not be queried" if queryFailed else ""]

func GetActivityTotal(activity : SQLStats.Activity, totals : Dictionary[SQLStats.Total, Variant]) -> String:
	match activity:
		SQLStats.Activity.ACCOUNTS_CREATED:		return str(totals[SQLStats.Total.ACCOUNTS])
		SQLStats.Activity.ACCOUNTS_ACTIVE:		return "%d online" % Peers.GetOnlineAccountCount()
		SQLStats.Activity.CHARACTERS_CREATED:	return str(totals[SQLStats.Total.CHARACTERS])
		SQLStats.Activity.CHARACTERS_ACTIVE:	return "%d online" % Peers.GetOnlineCharacterIDs().size()
	return ""

func RefreshActivity(totals : Dictionary[SQLStats.Total, Variant]):
	var header : PackedStringArray = ["", "Total / Online"]
	for period in PeriodNames:
		header.append(PeriodNames[period])

	var counts : Dictionary[SQLStats.Activity, Dictionary] = SQLStats.GetActivity()
	var rows : Array = []
	for activity in ActivityNames:
		var row : Array = [ActivityNames[activity], GetActivityTotal(activity, totals)]
		for period in PeriodNames:
			row.append(counts.get(activity, {}).get(period, 0))
		rows.append(row)
	FillTable("Activity", header, rows)

func RefreshStatistics(totals : Dictionary[SQLStats.Total, Variant]):
	var characterCount : int = totals[SQLStats.Total.CHARACTERS]
	var playTime : int = totals[SQLStats.Total.PLAY_TIME]
	FillTable("Statistics", ["Statistic", "Value"], [
		["Total play time", Util.FormatPlayTime(playTime)],
		["Average play time", Util.FormatPlayTime(floori(playTime / float(characterCount)) if characterCount > 0 else 0)],
		["Average level", "%.1f" % totals[SQLStats.Total.AVERAGE_LEVEL]],
		["Highest level", totals[SQLStats.Total.MAX_LEVEL]],
		["GP in circulation", totals[SQLStats.Total.GP]],
		["Quests completed", totals[SQLStats.Total.QUESTS_COMPLETED]],
		["Monsters killed", totals[SQLStats.Total.MONSTERS_KILLED]],
		["Items owned", totals[SQLStats.Total.ITEMS]],
		["Active bans", totals[SQLStats.Total.BANS]],
		["IP bans", totals[SQLStats.Total.IP_BANS]],
	])

func RefreshPlatforms():
	var rows : Array = []
	for entry in SQLStats.GetPlatforms():
		rows.append([NetworkCommons.GetPlatformName(entry.platform), entry.accounts])
	FillTable("Platforms", ["Platform", "Accounts"], rows)

func RefreshLatestAccounts():
	var rows : Array = []
	for entry in SQLStats.GetLatestAccounts(LatestAccountsSize):
		rows.append([
			entry.account_id,
			entry.username,
			Util.FormatDate(entry.created_timestamp),
			Util.FormatTimeAgo(entry.last_timestamp),
			NetworkCommons.GetPlatformName(entry.platform),
			entry.characters,
		])
	FillTable("Latest accounts", ["ID", "Username", "Created", "Last login", "Platform", "Characters"], rows)

#
func Refresh():
	var totals : Dictionary[SQLStats.Total, Variant] = SQLStats.GetTotals()
	RefreshPath(totals.is_empty())
	if totals.is_empty():
		return
	RefreshActivity(totals)
	RefreshStatistics(totals)
	RefreshPlatforms()
	RefreshLatestAccounts()
