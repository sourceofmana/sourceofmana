extends NpcScript

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		own.Interact(player)
