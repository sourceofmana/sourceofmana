extends RefCounted
class_name LeaderboardCommons

#
const DefaultSize : int						= 10

enum Category
{
	LEVEL = 0,
	PLAY_TIME,
	QUESTS,
	KILLS,
	WEALTH,
	COUNT
}

const CategoryNames : Dictionary[Category, String] = {
	Category.LEVEL: "Level",
	Category.PLAY_TIME: "Play time",
	Category.QUESTS: "Quests completed",
	Category.KILLS: "Monsters killed",
	Category.WEALTH: "Wealth",
}

#
static func FormatValue(category : Category, entry : Dictionary) -> String:
	match category:
		Category.LEVEL:		return "%d (%d exp)" % [entry.get("level", 0), entry.get("experience", 0)]
		Category.PLAY_TIME:	return Util.FormatPlayTime(entry.get("play_time", 0))
		Category.QUESTS:	return str(entry.get("quests", 0))
		Category.KILLS:		return str(entry.get("kills", 0))
		Category.WEALTH:	return "%d GP" % entry.get("gp", 0)
	return ""
