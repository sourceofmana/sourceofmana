extends AbilityScript

#
func Execute(agent : BaseAgent):
	if agent.stat.spirit == DB.UnknownHash or agent is not PlayerAgent:
		return

	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map and map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
		return

	agent.Morph(true)
