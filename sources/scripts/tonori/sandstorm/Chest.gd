extends NpcScript

# Quest ID
const questID : int = ProgressCommons.Quest.SANDSTORM_MINE_ABANDONED_TREASURE

# Required items
var chestMineKeyID : int = DB.GetCellHash("Chest Mine Key")

# Reward items
var shortSwordID : int = DB.GetCellHash("Short Sword")

#
func OnStart():
	match GetQuest(questID):
		ProgressCommons.SANDSTORM_MINE_ABANDONED_TREASURE.KEY_FOUND: OnTryOpen()
		ProgressCommons.SANDSTORM_MINE_ABANDONED_TREASURE.REWARDS_WITHDREW: OnEmpty()
		_: OnLocked()

func OnTryOpen():
	if not HasItem(chestMineKeyID):
		OnLocked()
		return

	if not IsTriggering():
		Trigger()

	if HasSpace(1):
		RemoveItem(chestMineKeyID, 1)
		SetQuest(questID, ProgressCommons.SANDSTORM_MINE_ABANDONED_TREASURE.REWARDS_WITHDREW)
		AddItem(shortSwordID, 1)

func OnEmpty():
	Chat("This chest is empty.")

func OnLocked():
	Chat("This chest is locked. You need a key.")
