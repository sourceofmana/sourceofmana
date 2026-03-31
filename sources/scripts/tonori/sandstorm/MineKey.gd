extends NpcScript

# Quest ID
const questID : int = ProgressCommons.Quest.SANDSTORM_MINE_ABANDONED_TREASURE

# Reward items
var chestMineKeyID : int = DB.GetCellHash("Chest Mine Key")

#
func OnStart():
	match GetQuest(questID):
		ProgressCommons.SANDSTORM_MINE_ABANDONED_TREASURE.INACTIVE:
			if HasSpace(1):
				SetQuest(questID, ProgressCommons.SANDSTORM_MINE_ABANDONED_TREASURE.KEY_FOUND)
				AddItem(chestMineKeyID, 1)
