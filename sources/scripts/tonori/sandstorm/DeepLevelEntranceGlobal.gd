extends NpcScript

#
const mapPos : Vector2i = Vector2i(1728, 2560)
var mapName : int = "Desert Deep Level".hash()

#
func OnAreaEnter(player : PlayerAgent):
	NpcCommons.WarpInstance(player, mapName, mapPos)
