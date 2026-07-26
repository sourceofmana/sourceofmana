extends WarpGlobal
class_name PortGlobal

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		if npc.spawnInfo.auto_warp:
			OnPortWarpConfirm(player)
		else:
			npc.Interact(player)

func OnAreaExit(player : PlayerAgent):
	if player and not npc.spawnInfo.auto_warp:
		NpcCommons.ToggleContext(player, false)
		player.ClearScript()

func OnPortWarpConfirm(player : PlayerAgent):
	var mapID : int = WorldAgent.GetMapFromAgent(npc).id
	var pos : Vector2 = npc.spawnInfo.disembark_pos if player.stat.IsSailing() else npc.spawnInfo.sailing_pos
	player.Morph(false, player.GetNextPortShapeID())
	NpcCommons.Warp(player, mapID, pos, npc.spawnInfo.direction)

func GetPortWarpField(player : PlayerAgent):
	return "Disembark" if player.stat.IsSailing() else "Sail"
