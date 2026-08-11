extends NpcScript

const questID : int = ProgressCommons.Quest.TULIMSHAR_EASTERN_HILLS_CHEST

var desertShieldID : int = DB.GetCellHash("Desert Shield")

#
func OnStart():
	match GetQuest(questID):
		ProgressCommons.TULIMSHAR_EASTERN_HILLS_CHEST.INACTIVE: OnOpen()
		_: OnEmpty()

func OnOpen():
	if not IsTriggering():
		Trigger()
	if HasSpace(1):
		SetQuest(questID, ProgressCommons.TULIMSHAR_EASTERN_HILLS_CHEST.REWARDS_WITHDREW)
		AddItem(desertShieldID, 1)

func OnEmpty():
	Chat("This chest is empty.")
