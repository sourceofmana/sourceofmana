extends NpcScript

const animationSpeed : float		= 30.0

# Reward items
var appleID : int					= DB.GetCellHash("Apple")

# Required items
var dorianKeyID : int				= DB.GetCellHash("Dorian's Key")
var gabrielKeyID : int				= DB.GetCellHash("Gabriel's Key")
var marvinKeyID : int				= DB.GetCellHash("Marvin's Key")

#
func OnStart():
	match GetQuest(ProgressCommons.QUEST_SPLATYNA_OFFERING):
		ProgressCommons.STATE_SPLATYNA.INACTIVE: Inactive()
		ProgressCommons.STATE_SPLATYNA.STARTED: TryOpen()
		_: Empty()

func Inactive():
	Chat("This chest seems to be sealed.")

func TryOpen():
	# Chest is not open, try to open it
	if not ActorCommons.IsTriggering(npc):
		# Check and remove items to open the chest
		if HasItem(dorianKeyID) and HasItem(gabrielKeyID) and HasItem(marvinKeyID):
			if RemoveItem(dorianKeyID) and RemoveItem(gabrielKeyID) and RemoveItem(marvinKeyID):
				Trigger()
				AddTimer(npc, animationSpeed, npc.ownScript.CloseChest)
		else:
			Chat("A lock with three holes is blocking this chest.")
			Chat("You will need three different keys to unlock it.")
	# Chest is opened, you can withdraw your reward
	else:
		if HasSpace(1):
			SetQuest(ProgressCommons.QUEST_SPLATYNA_OFFERING, ProgressCommons.STATE_SPLATYNA.REWARDS_WITHDREW)
			AddItem(appleID)

func Empty():
	Chat("This chest is empty.")
