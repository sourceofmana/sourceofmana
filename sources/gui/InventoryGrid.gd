extends GridContainer

const Tile = preload("res://scenes/gui/inventory/Tile.tscn")

var slots : Array = []

func _ready():
	for item in GlobalWorld.currentPlayer.inventory.items:
		var tileInstance	= Tile.instance()
		var itemReference	= GlobalWorld.currentPlayer.inventory.items[item]
		var iconTexture		= load(Launcher.Path.ItemRsc + itemReference._path)

		tileInstance.get_node("Icon").set_texture(iconTexture)
		tileInstance.hint_tooltip = itemReference._name

		add_child(tileInstance)
		slots.append(tileInstance)
