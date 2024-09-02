extends NpcScript

const animationSpeed : float		= 30.0
var rewardItemID : int				= DB.GetCellHash("Apple")
var keyItemID : int					= DB.GetCellHash("Dorian's Key")

# To remove once quest setters and getters are implemented
var withdrew : bool					= false

#
func OnStart():
	# Chest is not open, try to open it
	if not ActorCommons.IsTriggering(npc):
		# Remove the item and open the chest
		if RemoveItem(keyItemID):
			Trigger()
			AddTimer(npc, animationSpeed, npc.ownScript.CloseChest)
		else:
			Chat("You need a key to open this chest!")
	# Chest is opened, you can withdraw your reward
	else:
		# Check quest state
		if not withdrew:
			withdrew = true
			AddItem(rewardItemID)
		else:
			Chat("This chest is empty.")
