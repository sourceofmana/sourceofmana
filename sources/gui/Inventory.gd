extends WindowPanel

@onready var weightStat : Control		= $Margin/VBoxContainer/Weight/BgTex/Weight
@onready var grid : GridContainer		= $Margin/VBoxContainer/Container/Grid

#
func RefreshInventory():
	var tileIdx : int		= 0
	var tile : CellTile		= grid.tiles[tileIdx]

	for item in Launcher.Player.inventory.items:
		if item and item.cell:
			CellTile.RefreshShortcuts(item.cell, item.count)
			if item.cell.stackable:
				if tile:
					tile.AssignData(item.cell, item.count)
					tileIdx += 1
					tile = grid.GetTile(tileIdx)
				else:
					break
			else:
				for cellIdx in range(item.count):
					if tile:
						tile.AssignData(item.cell)
						tileIdx += 1
						tile = grid.GetTile(tileIdx)
					else:
						break

	for remainingIdx in range(tileIdx, grid.maxCount):
		grid.tiles[remainingIdx].AssignData(null, 0)

	weightStat.SetStat(Formula.GetWeight(Launcher.Player.inventory), Launcher.Player.stat.current.weightCapacity)
