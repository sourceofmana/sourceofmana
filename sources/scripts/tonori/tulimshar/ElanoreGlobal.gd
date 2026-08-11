extends NpcScript

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		if player.progress.GetQuest(ProgressCommons.Quest.TUTORIAL) == ProgressCommons.TUTORIAL.INACTIVE:
			own.Interact(player)
