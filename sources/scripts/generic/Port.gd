extends Warp

#
func OnStart():
	Choice(GetGlobal("GetPortWarpField").call(own), GetGlobal("OnPortWarpConfirm").bind(own))
	super.OnStart()
