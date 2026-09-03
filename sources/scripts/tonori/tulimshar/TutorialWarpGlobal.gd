extends WarpGlobal

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript and not player.isWarping and player.progress:
		if player.progress.GetQuest(ProgressCommons.Quest.TUTORIAL) < ProgressCommons.CompletedProgress:
			TriggerSkipTutorial(player)
		else:
			super.OnAreaEnter(player)

func TriggerSkipTutorial(player : PlayerAgent):
	var ekinuNPC : NpcAgent = GetNamedGlobalNPC("Ekinu")
	if ekinuNPC:
		player.AddScript(ekinuNPC)
		if player.ownScript:
			player.ownScript.step = 0
			player.ownScript.steps.clear()
			player.ownScript.OnSkipTutorial()
			player.ownScript.ApplyStep()
