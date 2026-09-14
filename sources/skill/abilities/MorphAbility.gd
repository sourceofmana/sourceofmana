extends CellScript

#
func Execute(target : BaseAgent, _cell : BaseCell):
	if target.stat.spirit == DB.UnknownHash or target is not PlayerAgent:
		return

	var map : WorldMap = WorldAgent.GetMapFromAgent(target)
	if map and map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
		return

	target.Morph(true)
