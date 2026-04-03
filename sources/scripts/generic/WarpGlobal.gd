extends NpcScript

#
var warpName : String = ""

#
func OnAreaEnter(player : PlayerAgent):
	if player and not player.ownScript:
		if npc.spawnInfo.auto_warp:
			OnWarpConfirm(player)
		else:
			npc.Interact(player)

func OnWarpConfirm(player : PlayerAgent):
	NpcCommons.Warp(player, npc.spawnInfo.destination_map, npc.spawnInfo.destination_pos)

func GetWarpField(_player : PlayerAgent) -> String:
	return warpName

#
func OnStart():
	var mapData : FileData = DB.MapsDB.get(npc.spawnInfo.destination_map, null)
	if mapData:
		warpName = mapData._name
