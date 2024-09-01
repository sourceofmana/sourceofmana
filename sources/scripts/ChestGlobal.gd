extends NpcScript

const animationSpeed : float		= 30.0
const rewardItemID : int			= 0
const keyItemID : int				= 1

#
func CloseChest():
	if ActorCommons.IsTriggering(npc):
		Trigger()
