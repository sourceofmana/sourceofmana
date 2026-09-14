extends CellScript

#
func Execute(target : BaseAgent, _cell : BaseCell):
	target.SetRunning(not target.stat.isRunning)
