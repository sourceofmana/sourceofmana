extends Object
class_name EntityInventory

# var capacity					= 100

signal content_changed

var items: Array[InventoryItem] = []

func _init():
	# fill inventory
	add_item(load("res://data/items/apple.tres"), 14)
	add_item(load("res://data/items/pineapple.tres"), 3)
	add_item(load("res://data/items/grumpys_key.tres"))
	add_item(load("res://data/items/hungrys_key.tres"), 2)
	add_item(load("res://data/items/pineapple.tres"), 9)
	add_item(load("res://data/items/corn.tres"), 5)

func add_item(type: BaseItem, count: int = 1):
	# add to existing item "pile" if it is stackable
	if type.stackable:
		for item in items:
			if item.type == type:
				item.count += count
				return
		items.append(InventoryItem.new(type, count))
	else:
		if count > 1:
			for _c in range(0, count):
				items.append(InventoryItem.new(type, 1))
		else:
			items.append(InventoryItem.new(type, 1))
	content_changed.emit()


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
			_remove_one_item(inv_item)

func _remove_one_item(item: InventoryItem):
	item.count -= 1
	if item.count <= 0:
		items.erase(item)
	content_changed.emit()
