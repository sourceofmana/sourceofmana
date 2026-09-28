extends CellScript

#
func Execute(target : BaseAgent, _cell : BaseCell):
	var bottle : ItemCell = DB.GetItem(DB.GetCellHash("Bottle"))
	if bottle and target.inventory:
		if not target.inventory.AddItem(bottle):
			WorldDrop.PushDrop(Item.new(bottle), target)
