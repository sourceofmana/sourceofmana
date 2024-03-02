extends WindowPanel

@onready var weightStat : Control		= $Margin/VBoxContainer/Weight/BgTex/Weight
@onready var itemGrid : GridContainer	= $Margin/VBoxContainer/ItemContainer/Grid
@onready var itemContainer : Container	= $Margin/VBoxContainer/ItemContainer

#
func initialize():
	Launcher.Player.inventory.content_changed.connect(update_inventory)
	update_inventory()

func update_inventory():
	# display inventory
	update_inventory_ui()
	# update weight
	weightStat.SetStat(Formulas.GetWeight(Launcher.Player.inventory), Launcher.Player.stat.current.weightCapacity)

# render inventory items to ui
func update_inventory_ui():
	for oldItem in itemGrid.get_children():
		itemGrid.remove_child(oldItem)
		oldItem.ItemClicked.disconnect(_on_item_click)
		oldItem.queue_free()

	var tilePreset = FileSystem.LoadGui("inventory/ItemGridTile", false)
	for item in Launcher.Player.inventory.items:
		var tileInstance : InventoryItemGridTile = tilePreset.instantiate()
		tileInstance.set_data(item)
		tileInstance.ItemClicked.connect(_on_item_click)
		itemGrid.add_child.call_deferred(tileInstance)

func _on_item_click(item: InventoryItem):
	Launcher.Player.inventory.use_item(item)
