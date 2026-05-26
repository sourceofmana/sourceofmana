extends WarpGlobal

#
func OnAreaEnter(player : PlayerAgent):
	if player and player.progress:
		if player.progress.GetQuest(ProgressCommons.Quest.TUTORIAL) < ProgressCommons.TUTORIAL.ELANORE_DONE:
			Network.PushNotification("You should speak with Elanore before leaving.", player.peerID)
			return
	super.OnAreaEnter(player)
