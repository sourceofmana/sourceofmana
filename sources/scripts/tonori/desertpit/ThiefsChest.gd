extends NpcScript

# Quest ID
const questID : int = ProgressCommons.Quest.SNAKE_PIT_THIEF

# Reward items
var scimitarID : int = DB.GetCellHash("Scimitar")

# Required items
var thiefsKeyID : int = DB.GetCellHash("Thief's Key")

#
func OnStart():
	match GetQuest(questID):
		ProgressCommons.SNAKE_PIT_THIEF.RIDDLE_SOLVED: OnTryOpen()
		ProgressCommons.SNAKE_PIT_THIEF.REWARDS_WITHDREW: OnEmpty()
		_: OnLocked()

func OnTryOpen():
	if not HasItem(thiefsKeyID):
		OnLocked()
		return

	ExchangeItems([thiefsKeyID], [scimitarID], OnChestExchanged)

func OnChestExchanged(result : ActorInventory.ExchangeResult):
	match result:
		ActorInventory.ExchangeResult.OK:
			if not IsTriggering():
				Trigger()
			SetQuest(questID, ProgressCommons.SNAKE_PIT_THIEF.REWARDS_WITHDREW)
			AddGP(200)
			AddExp(50)
			AddKarma(2)
		ActorInventory.ExchangeResult.MISSING_ITEMS:
			OnLocked()
		ActorInventory.ExchangeResult.NO_SPACE:
			Chat("Your bag is too full to take anything from this chest.")

func OnEmpty():
	Chat("This chest is empty.")

func OnLocked():
	Chat("This chest is locked. You need a key.")
