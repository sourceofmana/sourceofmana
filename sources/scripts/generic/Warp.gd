extends NpcScript
class_name Warp

#
func OnStart():
	if not npc.ownScript.warpName.is_empty():
		Choice(GetGlobal("GetWarpField").call(own), GetGlobal("OnWarpConfirm").bind(own))
	Choice("Cancel", Callback.Empty)
