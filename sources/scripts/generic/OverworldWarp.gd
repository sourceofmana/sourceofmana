extends WarpGlobal

#
func OnWarpConfirm(player : PlayerAgent):
	var nextShaderID : int = player.GetNextPortShapeID()
	player.Morph(false, nextShaderID)

	var destPos : Vector2 = npc.spawnInfo.destination_pos
	if nextShaderID == DB.ShipHash and destPos == Vector2.ZERO:
		destPos = player.exploreOrigin.pos

	NpcCommons.Warp(player, npc.spawnInfo.destination_map, destPos, npc.spawnInfo.direction)
