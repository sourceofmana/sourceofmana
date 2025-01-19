extends GridContainer

#
@export var maxCount : int				= 100
var tiles : Array[CellTile]				= []

#
func GetTile(idx : int) -> CellTile:
	return tiles[idx] if idx < maxCount else null

#
func _on_panel_resized():
	var firstTile : CellTile = GetTile(0)
	var tileSize : int = firstTile.size.x + get("theme_override_constants/h_separation") if firstTile else 0
	if tileSize > 0:
		columns = max(1, int(size.x / tileSize))
	else:
		columns = maxCount

func _ready():
	tiles.resize(maxCount)
	for tileIdx in range(maxCount):
		var tile : CellTile = UICommons.CellTilePreset.instantiate()
		tile.AssignData(null, 0)
		tiles[tileIdx] = tile
		add_child.call_deferred(tile)

func _on_gui_input(event : InputEvent):
	Launcher.Action.TryConsume(event, "gp_zoom_in")
	Launcher.Action.TryConsume(event, "gp_zoom_out")
