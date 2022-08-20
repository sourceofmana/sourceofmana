extends GridContainer

const Tile = preload("res://scenes/gui/inventory/Tile.tscn")

var slots : Array = []

func _ready():
	if Launcher.Entities.activePlayer:
		for item in Launcher.Entities.activePlayer.inventory.items:
			var tileInstance	= Tile.instantiate()
			var itemReference	= Launcher.Entities.activePlayer.inventory.items[item]
			var iconTexture		= load(Launcher.Path.ItemRsc + itemReference._path)

			tileInstance.get_node("Icon").set_texture(iconTexture)
			tileInstance.hint_tooltip = itemReference._name

			add_child(tileInstance)
			slots.append(tileInstance)
