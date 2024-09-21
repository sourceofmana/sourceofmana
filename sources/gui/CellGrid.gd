extends GridContainer

#
@export var maxCount : int				= 100
var tiles : Array[CellTile]				= []

#
func GetTile(idx : int) -> CellTile:
	return tiles[idx] if idx < maxCount else null

#
func _on_panel_resized():
	if get_child_count() > 0:
		var tileSize : int = get_child(0).size.x + get("theme_override_constants/h_separation")
		columns = max(1, int(get_parent().get_size().x / tileSize))
	else:
		columns = 100

func _ready():
	tiles.resize(maxCount)

	get_parent().resized.connect(_on_panel_resized)
	for tileIdx in range(maxCount):
		var tile : CellTile = UICommons.CellTilePreset.instantiate()
		tile.AssignData(null, 0)
		tiles[tileIdx] = tile
		add_child(tile)
