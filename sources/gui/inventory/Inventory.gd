extends WindowPanel

@onready var weightStat : Control		= $VBoxContainer/Weight/BgTex/Weight
@onready var itemGrid : GridContainer	= $VBoxContainer/ItemContainer/Grid
@onready var itemContainer : Container	= $VBoxContainer/ItemContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	itemContainer.resized.connect(_on_panel_resized)
	
func initialize():
	Launcher.Player.inventory.content_changed.connect(update_inventory)
	update_inventory()

func _on_panel_resized():
	if itemGrid.get_child_count() > 0:
		var h_separation = itemGrid.get("theme_override_constants/h_separation")
		var tileSize = get_child(0).size.x + h_separation
		itemGrid.columns = max(1, int(get_parent().get_size().x / tileSize))
	else:
		itemGrid.columns = 100

func update_inventory():
	# display inventory
	update_inventory_ui()
	# update weight
	weightStat.SetStat(Launcher.Player.inventory.calculate_weight() / 1000, Launcher.Player.stat.maxWeight / 1000)

# render inventory items to ui
func update_inventory_ui():
	for oldItem in itemGrid.get_children():
		itemGrid.remove_child(oldItem)
		oldItem.disconnect("ItemClicked", _on_item_click)
		oldItem.queue_free()

	var tilePreset = Launcher.FileSystem.LoadGui("inventory/ItemGridTile", false)
	for item in Launcher.Player.inventory.items:
		var tileInstance : InventoryItemGridTile = tilePreset.instantiate()
		tileInstance.set_data(item)
		tileInstance.connect("ItemClicked", _on_item_click)
		itemGrid.add_child(tileInstance)

func _on_item_click(item: InventoryItem):
	Launcher.Player.inventory.use_item(item)

