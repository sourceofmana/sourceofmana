extends Object
class_name InventoryItem

@export var type: BaseItem
@export var count: int

func is_stackable():
	type.stackable

func _init(p_type: BaseItem, p_count: int):
	type = p_type
	count = p_count
	
