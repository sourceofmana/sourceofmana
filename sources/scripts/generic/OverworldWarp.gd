extends WarpGlobal

#
func OnWarpConfirm(player : PlayerAgent):
	player.Morph(false, player.GetNextPortShapeID())
	NpcCommons.Warp(player, npc.spawnInfo.destination_map, npc.spawnInfo.destination_pos, npc.spawnInfo.direction)
