extends WindowPanel

@onready var weightStat : Control		= $Margin/VBoxContainer/Weight/BgTex/Weight
@onready var grid : GridContainer		= $Margin/VBoxContainer/Container/Grid
const tilePreset : Resource				= preload("res://presets/gui/inventory/ItemTile.tscn")
var tiles : Array[ItemTile]				= []

#
func GetTile(idx : int) -> ItemTile:
	return tiles[idx] if idx < ActorCommons.InventorySize else null

#
func RefreshInventory():
	var tileIdx : int		= 0
	var tile : ItemTile		= tiles[tileIdx]

	for item in Launcher.Player.inventory.items:
		if item and item.cell:
			if item.cell.stackable:
				if tile:
					tile.SetData(item.cell, item.count)
					tileIdx += 1
					tile = GetTile(tileIdx)
				else:
					break
			else:
				for cellIdx in range(item.count):
					if tile:
						tile.SetData(item.cell)
						tileIdx += 1
						tile = GetTile(tileIdx)
					else:
						break

	for remainingIdx in range(tileIdx, ActorCommons.InventorySize):
		tiles[remainingIdx].SetData(null, 0)

	weightStat.SetStat(Formula.GetWeight(Launcher.Player.inventory), Launcher.Player.stat.current.weightCapacity)

#
func _ready():
	tiles.resize(ActorCommons.InventorySize)
	for tileIdx in range(ActorCommons.InventorySize):
		var tile : ItemTile = tilePreset.instantiate()
		tile.SetData(null, 0)
		tiles[tileIdx] = tile
		grid.add_child(tile)
