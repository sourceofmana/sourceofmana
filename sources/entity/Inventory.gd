extends Object
class_name EntityInventory

# var capacity					= 100

var items: Array[InventoryItem] = []

func _init():
	# fill inventory
	items.append(
		InventoryItem.new(load("res://data/items/apple.tres"), 14)
	)
	items.append(
		InventoryItem.new(load("res://data/items/pineapple.tres"), 3)
	)
	items.append(
		InventoryItem.new(load("res://data/items/grumpys_key.tres"), 1)
	)
	items.append(
		InventoryItem.new(load("res://data/items/hungrys_key.tres"), 2)
	)


func calculate_weight():
	var weight = 0
	for item in items:
		weight += item.type.weight * item.count
	return weight


func use_item(item: InventoryItem):
	var inv_item_index = items.find(item)
	var inv_item = items[inv_item_index]
	print(inv_item.type.name)
	if inv_item:
		inv_item.type.use()
		if inv_item.type is FoodItem:
			Launcher.Entities.playerEntity.stat.health += (inv_item.type as FoodItem).HealthPoints
			inv_item.count -= 1
			if inv_item.count <= 0:
				items.erase(inv_item)
