extends GridContainer

#
signal ItemClicked

const Tile = preload("res://scenes/gui/inventory/Tile.tscn")

var slots : Array = []

#
func FillGridContainer(listOfItem : Dictionary):
	if listOfItem:
		for item in listOfItem:
			var tileInstance : ColorRect	= Tile.instantiate()
			var itemReference : Object		= listOfItem[item]
			var itemTexture : Texture2D		= Launcher.FileSystem.LoadGfx(itemReference._path)

			Launcher.Util.Assert(tileInstance.has_node("Icon"), "Could not find the Icon node:" + itemReference._name)
			if tileInstance.has_node("Icon"):
				var iconNode = tileInstance.get_node("Icon")
				iconNode.set_normal_texture(itemTexture)
				iconNode.button_down.connect(OnItemPressed.bind(item))

			var tooltip : String = itemReference._name
			if itemReference._description != "":
				tooltip += "\n" + itemReference._description
			tileInstance.set_tooltip_text(tooltip)
			tileInstance.set_name(item)

			add_child(tileInstance)
			slots.append(tileInstance)
		_on_panel_resized()

func OnItemPressed(item : String):
	emit_signal('ItemClicked', item)

#
func _on_panel_resized():
	if get_child_count() > 0:
		var tileSize = get_child(0).size.x + get("theme_override_constants/h_separation")
		columns = max(1, int(get_parent().get_size().x / tileSize))
	else:
		columns = 100

func _ready():
	get_parent().resized.connect(_on_panel_resized)
