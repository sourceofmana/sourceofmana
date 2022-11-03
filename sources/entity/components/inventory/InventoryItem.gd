extends Object
class_name InventoryItem

@export var type: BaseItem
@export var count: int

func is_stackable():
	return type.stackable

func _init(p_type: BaseItem, p_count: int):
	type = p_type
	if p_count > 1 and not type.stackable:
		printerr("trying to create an InventoryItem with multiple items, but the type is not stackable")
	count = p_count
	
