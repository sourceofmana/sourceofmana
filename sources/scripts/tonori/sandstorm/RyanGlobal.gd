extends NpcScript

const QUEST_ID : int = ProgressCommons.Quest.MINE_EXPLORATION

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		match player.progress.GetQuest(QUEST_ID):
			ProgressCommons.MINE_EXPLORATION.STARTED, ProgressCommons.MINE_EXPLORATION.MANA_TREE_MET:
				own.Interact(player)
				
