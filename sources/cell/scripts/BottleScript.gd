extends CellScript

#
func Execute(target : BaseAgent, _cell : BaseCell):
	var bottle : ItemCell = DB.GetItem(DB.GetCellHash("Bottle"))
	if bottle and target.inventory:
		target.inventory.AddItem(bottle)
