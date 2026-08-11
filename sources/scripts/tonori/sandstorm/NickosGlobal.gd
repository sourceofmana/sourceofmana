extends NpcScript

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		if player.progress.GetQuest(ProgressCommons.Quest.MINE_EXPLORATION) == ProgressCommons.MINE_EXPLORATION.FIND_NICKOS:
			own.Interact(player)
