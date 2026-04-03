extends NpcScript

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		if npc.spawnInfo.auto_warp:
			OnWarpConfirm(player)
		else:
			npc.Interact(player)

func OnWarpConfirm(player : PlayerAgent):
	var pos : Vector2 = npc.spawnInfo.destination_pos
	if not player.stat.IsSailing():
		pos = npc.spawnInfo.sailing_pos
	player.Morph(false, player.GetNextPortShapeID())
	NpcCommons.Warp(player, npc.spawnInfo.destination_map, pos)

func GetWarpField(player : PlayerAgent) -> String:
	return "Disembark" if player.stat.IsSailing() else "Sail"
