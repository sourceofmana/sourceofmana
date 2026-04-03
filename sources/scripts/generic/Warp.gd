extends NpcScript

#
func OnStart():
	Choice(GetGlobal("GetWarpField").call(own), OnConfirm)
	Choice("Cancel", Callback.Empty)

func OnConfirm():
	Action(GetGlobal("OnWarpConfirm").bind(own))
