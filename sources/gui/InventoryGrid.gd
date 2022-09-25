extends GridContainer

const Tile = preload("res://scenes/gui/inventory/Tile.tscn")

var slots : Array = []

func _ready():
	if Launcher.Entities.activePlayer:
		for item in Launcher.Entities.activePlayer.inventory.items:
			var tileInstance : ColorRect	= Tile.instantiate()
			var itemReference : Object		= Launcher.Entities.activePlayer.inventory.items[item]
			var iconTexture : Texture2D		= Launcher.FileSystem.LoadItem(itemReference._path)

			if tileInstance.has_node("Icon"):
				var iconNode = tileInstance.get_node("Icon")
				iconNode.set_texture(iconTexture)
			else:
				Launcher.Util.Assert(false, "Could not find the Icon node for item:" + itemReference._name)

			var tooltip : String = itemReference._name + "\n" + itemReference._description
			tileInstance.set_tooltip_text(tooltip)

			tileInstance.set_name(itemReference._name)
			add_child(tileInstance)
			slots.append(tileInstance)
		_on_panel_resized()

func _on_panel_resized():
	var tileSize = 38 # Tile.size.x + h_separation 
	if get_child_count() > 0:
		tileSize = get_child(0).size.x + get("theme_override_constants/h_separation")

	set_columns(int(get_parent().get_size().x / tileSize))
