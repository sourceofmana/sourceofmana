extends NpcScript

const animationSpeed : float		= 30.0

func OnTrigger():
	AddTimer(npc, animationSpeed, CloseChest)

#
func CloseChest():
	if IsTriggering():
		Trigger()
