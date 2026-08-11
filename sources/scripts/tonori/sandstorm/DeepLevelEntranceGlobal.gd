extends NpcScript

#
const mapPos : Vector2i = Vector2i(1760, 2560)
var mapName : int = "Desert Deep Level".hash()

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript and not player.isWarping:
		var questState : int = player.progress.GetQuest(ProgressCommons.Quest.MINE_EXPLORATION)
		if questState == ProgressCommons.MINE_EXPLORATION.STRANGER_SPOTTED:
			npc.Interact(player)
		elif questState > ProgressCommons.MINE_EXPLORATION.STRANGER_SPOTTED and questState < ProgressCommons.CompletedProgress:
			NpcCommons.WarpInstance(player, mapName, mapPos)
