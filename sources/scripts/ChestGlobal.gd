extends NpcScript

#
func CloseChest():
	if ActorCommons.IsTriggering(npc):
		Trigger()
