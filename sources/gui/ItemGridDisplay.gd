extends GridContainer

#
@onready var tilePreset : Resource		= FileSystem.LoadGui("emotes/Tile", false)
var slots : Array						= []

#
func FillGridContainer(cells : Dictionary):
	for cell in cells:
		var tileInstance : ColorRect	= tilePreset.instantiate()
		Util.Assert(tileInstance.has_node("Icon"), "Could not find the Icon node:" + cell)

		if tileInstance.has_node("Icon"):
			var iconNode : Node = tileInstance.get_node("Icon")
			iconNode.set_texture_normal(cells[cell].icon)
			Callback.PlugCallback(iconNode.button_down, cells[cell].Use)

		tileInstance.set_tooltip_text(cell)
		tileInstance.set_name(cell)

		add_child(tileInstance)
		slots.append(tileInstance)
	_on_panel_resized()

#
func _on_panel_resized():
	if get_child_count() > 0:
		var tileSize : int = get_child(0).size.x + get("theme_override_constants/h_separation")
		columns = max(1, int(get_parent().get_size().x / tileSize))
	else:
		columns = 100

func _ready():
	get_parent().resized.connect(_on_panel_resized)
