extends CellScript

#
func Execute(agent : BaseAgent):
	agent.SetRunning(not agent.stat.isRunning)
