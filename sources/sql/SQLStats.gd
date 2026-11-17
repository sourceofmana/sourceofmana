extends RefCounted
class_name SQLStats

#
const DaySec : int							= 24 * 3600

enum Period { DAY, WEEK, MONTH }
const PeriodSec : Dictionary[Period, int] = {
	Period.DAY: DaySec,
	Period.WEEK: DaySec * 7,
	Period.MONTH: DaySec * 30,
}

enum Activity { ACCOUNTS_CREATED, ACCOUNTS_ACTIVE, CHARACTERS_CREATED, CHARACTERS_ACTIVE }
const ActivityQueries : Dictionary[Activity, String] = {
	Activity.ACCOUNTS_CREATED: "SELECT COUNT(*) FROM account WHERE created_timestamp >= {since}",
	Activity.ACCOUNTS_ACTIVE: "SELECT COUNT(*) FROM account WHERE last_timestamp >= {since}",
	Activity.CHARACTERS_CREATED: "SELECT COUNT(*) FROM character WHERE created_timestamp >= {since}",
	Activity.CHARACTERS_ACTIVE: "SELECT COUNT(*) FROM character WHERE last_timestamp >= {since}",
}

enum Total { ACCOUNTS, CHARACTERS, PLAY_TIME, AVERAGE_LEVEL, MAX_LEVEL, GP, QUESTS_COMPLETED, MONSTERS_KILLED, ITEMS, BANS, IP_BANS }
const TotalQueries : Dictionary[Total, String] = {
	Total.ACCOUNTS: "SELECT COUNT(*) FROM account",
	Total.CHARACTERS: "SELECT COUNT(*) FROM character",
	Total.PLAY_TIME: "SELECT IFNULL(SUM(total_time), 0) FROM character",
	Total.AVERAGE_LEVEL: "SELECT IFNULL(AVG(level), 0.0) FROM stat",
	Total.MAX_LEVEL: "SELECT IFNULL(MAX(level), 0) FROM stat",
	Total.GP: "SELECT IFNULL(SUM(gp), 0) FROM stat",
	Total.QUESTS_COMPLETED: "SELECT COUNT(*) FROM quest WHERE state = {completed}",
	Total.MONSTERS_KILLED: "SELECT IFNULL(SUM(killed_count), 0) FROM bestiary",
	Total.ITEMS: "SELECT IFNULL(SUM(count), 0) FROM item",
	Total.BANS: "SELECT COUNT(*) FROM ban WHERE unban_timestamp > {now}",
	Total.IP_BANS: "SELECT COUNT(*) FROM ip_ban",
}

const LeaderboardOrders : Dictionary[LeaderboardCommons.Category, String] = {
	LeaderboardCommons.Category.LEVEL: "level DESC, experience DESC",
	LeaderboardCommons.Category.PLAY_TIME: "play_time DESC",
	LeaderboardCommons.Category.QUESTS: "quests DESC, level DESC",
	LeaderboardCommons.Category.KILLS: "kills DESC",
	LeaderboardCommons.Category.WEALTH: "gp DESC",
}

# Global
static func GetTotals() -> Dictionary[Total, Variant]:
	var bindings : Dictionary = GetBindings()
	var columns : PackedStringArray = []
	for total in TotalQueries:
		columns.append("(%s) AS t%d" % [TotalQueries[total].format(bindings), total])

	var totals : Dictionary[Total, Variant] = {}
	var results : Array[Dictionary] = Launcher.SQL.Query("SELECT %s;" % ", ".join(columns))
	if not results.is_empty():
		for total in TotalQueries:
			totals[total] = results[0].get("t%d" % total, 0)
	return totals

static func GetActivity() -> Dictionary[Activity, Dictionary]:
	var now : int = SQLCommons.Timestamp()
	var columns : PackedStringArray = []
	for activity in ActivityQueries:
		for period in PeriodSec:
			columns.append("(%s) AS a%d_%d" % [ActivityQueries[activity].format({"since": now - PeriodSec[period]}), activity, period])

	var counts : Dictionary[Activity, Dictionary] = {}
	var results : Array[Dictionary] = Launcher.SQL.Query("SELECT %s;" % ", ".join(columns))
	if not results.is_empty():
		for activity in ActivityQueries:
			var periodCounts : Dictionary[Period, int] = {}
			for period in PeriodSec:
				periodCounts[period] = results[0].get("a%d_%d" % [activity, period], 0)
			counts[activity] = periodCounts
	return counts

static func GetPlatforms() -> Array[Dictionary]:
	return Launcher.SQL.Query("SELECT IFNULL(platform, 0) AS platform, COUNT(*) AS accounts FROM account GROUP BY IFNULL(platform, 0) ORDER BY accounts DESC;")

# Accounts
static func GetLatestAccounts(limit : int) -> Array[Dictionary]:
	return Launcher.SQL.Query("SELECT account.account_id, account.username, account.created_timestamp, \
		IFNULL(account.last_timestamp, 0) AS last_timestamp, IFNULL(account.platform, 0) AS platform, COUNT(character.char_id) AS characters \
		FROM account LEFT JOIN character ON character.account_id = account.account_id \
		GROUP BY account.account_id ORDER BY account.created_timestamp DESC LIMIT %d;" % limit)

# Characters
static func GetLastActiveCharacters(limit : int) -> Array[Dictionary]:
	return GetCharacters("last_timestamp DESC", limit)

static func GetLatestCharacters(limit : int) -> Array[Dictionary]:
	return GetCharacters("created_timestamp DESC", limit)

static func GetLeaderboard(category : LeaderboardCommons.Category, limit : int = LeaderboardCommons.DefaultSize) -> Array[Dictionary]:
	return GetCharacters(LeaderboardOrders[category], limit)

static func GetCharacters(order : String, limit : int) -> Array[Dictionary]:
	var onlineList : PackedStringArray = []
	for charID in Peers.GetOnlineCharacterIDs():
		onlineList.append(str(charID))

	if onlineList.is_empty():
		onlineList.append("NULL")

	return Launcher.SQL.Query("SELECT character.char_id AS char_id, character.nickname AS nickname, account.username AS username, character.created_timestamp AS created_timestamp, \
		IFNULL(character.last_timestamp, 0) AS last_timestamp, IFNULL(character.pos_map, 0) AS pos_map, \
		IFNULL(stat.level, 0) AS level, IFNULL(stat.experience, 0) AS experience, IFNULL(stat.gp, 0) AS gp, \
		character.char_id IN ({online}) IS 1 AS online, \
		IFNULL(character.total_time, 0) + CASE WHEN character.char_id IN ({online}) THEN MAX(0, {now} - IFNULL(character.last_timestamp, {now})) ELSE 0 END AS play_time, \
		(SELECT COUNT(*) FROM quest WHERE quest.char_id = character.char_id AND quest.state = {completed}) AS quests, \
		(SELECT IFNULL(SUM(killed_count), 0) FROM bestiary WHERE bestiary.char_id = character.char_id) AS kills \
		FROM character \
		INNER JOIN account ON account.account_id = character.account_id \
		LEFT JOIN stat ON stat.char_id = character.char_id \
		ORDER BY {order} LIMIT {limit};".format(GetBindings().merged({"online": ", ".join(onlineList), "order": order, "limit": limit})))

#
static func GetBindings() -> Dictionary:
	return {
		"now": SQLCommons.Timestamp(),
		"completed": ProgressCommons.CompletedProgress,
	}
