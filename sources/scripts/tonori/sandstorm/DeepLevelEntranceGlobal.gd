extends NpcScript

#
const mapPos : Vector2i = Vector2i(1760, 2560)
var mapName : int = "Desert Deep Level".hash()

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		if player.progress.GetQuest(ProgressCommons.Quest.MINE_EXPLORATION) >= ProgressCommons.MINE_EXPLORATION.STRANGER_SPOTTED:
			NpcCommons.WarpInstance(player, mapName, mapPos)
