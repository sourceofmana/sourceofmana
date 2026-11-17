extends ServerTableTab

#
func FillLeaderboard(category : LeaderboardCommons.Category):
	var title : String = LeaderboardCommons.CategoryNames[category]
	var rows : Array = []
	var rank : int = 1
	for entry in SQLStats.GetLeaderboard(category):
		rows.append([rank, entry.nickname, entry.username, LeaderboardCommons.FormatValue(category, entry)])
		rank += 1
	FillTable(title, ["#", "Character", "Account", title], rows)

#
func Refresh():
	for category in LeaderboardCommons.Category.COUNT:
		FillLeaderboard(category as LeaderboardCommons.Category)
