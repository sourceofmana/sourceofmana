extends WindowPanel
class_name InventoryWindow

@onready var weightStat : Control		= $VBoxContainer/Weight/BgTex/Weight
@onready var itemGrid : GridContainer	= $VBoxContainer/ItemContainer/Grid

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/ItemContainer.resized.connect(_on_panel_resized)
	# fill inventory
	inventory.append(
		InventoryItem.new(load("res://data/items/apple.tres"), 14)
	)
	inventory.append(
		InventoryItem.new(load("res://data/items/pineapple.tres"), 3)
	)
	inventory.append(
		InventoryItem.new(load("res://data/items/grumpys_key.tres"), 1)
	)
	inventory.append(
		InventoryItem.new(load("res://data/items/hungrys_key.tres"), 2)
	)

func _on_panel_resized():
	print("resized")
	if itemGrid.get_child_count() > 0:
		var tileSize = get_child(0).size.x + get("theme_override_constants/h_separation")
		itemGrid.columns = max(1, int(get_parent().get_size().x / tileSize))
	else:
		itemGrid.columns = 100

var timeout = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timeout += delta

var inventory : Array[InventoryItem] = []

func update_inventory():
	# crude debounce
	if timeout <= 1.0:
		return
	timeout = 0.0
	print("update_inventory") # this is print too often, TODO make sure this function is only called when needed
	# display inventory
	update_inventory_ui()
	calculate_weight()


const Tile = preload("res://scenes/gui/inventory/ItemGridTile.tscn")

# render inventory items to ui
func update_inventory_ui():
	print("update_inventory_ui")
	for oldItem in itemGrid.get_children():
		itemGrid.remove_child(oldItem)
		oldItem.disconnect("ItemClicked", _on_item_click)
		oldItem.queue_free()
	
	for item in inventory:
		var tileInstance : InventoryItemGridTile = Tile.instantiate()
		tileInstance.set_data(item)
		tileInstance.connect("ItemClicked", _on_item_click)
		itemGrid.add_child(tileInstance)
	
	
func calculate_weight():
	var weight = 0
	for item in inventory:
		weight += item.type.weight * item.count
	weightStat.SetStat(weight, Launcher.Entities.playerEntity.stat.maxWeight)


func _on_item_click(item: InventoryItem):
	var inv_item_index = inventory.find(item)
	var inv_item = inventory[inv_item_index]
	print(inv_item.type.name)
	if inv_item:
		inv_item.type.use()
		if inv_item.type is FoodItem:
			Launcher.Entities.playerEntity.stat.health += (inv_item.type as FoodItem).HealthPoints
			inv_item.count -= 1
			if inv_item.count <= 0:
				inventory.erase(inv_item)
	
	
