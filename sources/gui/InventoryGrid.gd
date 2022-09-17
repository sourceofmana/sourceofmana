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

			add_child(tileInstance)
			slots.append(tileInstance)
