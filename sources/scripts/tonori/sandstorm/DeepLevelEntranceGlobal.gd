extends NpcScript

#
const mapPos : Vector2i = Vector2i(1760, 2560)
var mapName : int = "Desert Deep Level".hash()

#
func OnAreaEnter(player : PlayerAgent):
	NpcCommons.WarpInstance(player, mapName, mapPos)
