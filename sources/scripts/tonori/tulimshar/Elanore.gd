extends NpcScript

#
var runID : int = DB.GetCellHash("Run")

#
func OnStart():
	if not HasSkill(runID):
		Mes("If one day, for no particular reason you decide to go for a little run.")
		TeachSkill(runID)
		Mes("Now you know how!")
