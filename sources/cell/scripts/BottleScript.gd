extends CellScript

#
func Execute(agent : BaseAgent):
	var bottle : ItemCell = DB.GetItem(DB.GetCellHash("Bottle"))
	if bottle and agent.inventory:
		agent.inventory.AddItem(bottle)
