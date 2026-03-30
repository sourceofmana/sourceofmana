extends NpcScript

# Quest ID
const questID : int = ProgressCommons.Quest.MINE_CHEST

# Reward items
var chestMineKeyID : int = DB.GetCellHash("Chest Mine Key")

#
func OnStart():
	match GetQuest(questID):
		ProgressCommons.MINE_CHEST.INACTIVE:
			if HasSpace(1):
				SetQuest(questID, ProgressCommons.MINE_CHEST.KEY_FOUND)
				AddItem(chestMineKeyID, 1)
