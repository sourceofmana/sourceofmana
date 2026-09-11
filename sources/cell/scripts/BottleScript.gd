extends CellScript

#
func Execute(agent : BaseAgent, _cell : BaseCell):
	var bottle : ItemCell = DB.GetItem(DB.GetCellHash("Bottle"))
	if bottle and agent.inventory:
		agent.inventory.AddItem(bottle)
