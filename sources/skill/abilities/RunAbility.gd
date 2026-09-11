extends CellScript

#
func Execute(agent : BaseAgent, _cell : BaseCell):
	agent.SetRunning(not agent.stat.isRunning)
