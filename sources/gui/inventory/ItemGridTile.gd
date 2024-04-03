extends ColorRect
class_name InventoryItemGridTile

signal ItemClicked(InventoryItem)

var item : Item

func set_data(p_item: Item):
	item = p_item
	$Icon.set_texture_normal(item.type.icon)
	if item.count >= 1000:
		$Label.text = "999+"
	elif item.count <= 1:
		$Label.text = ""
	else:
		$Label.text = str(item.count)
	
	var tooltip : String = item.type.name
	if item.type.description:
		tooltip += "\n" + item.type.description
	
	if item.type.weight == 0:
		tooltip += "\n\nWeight: " + str(item.type.weight) + "g"
	
	$Icon.tooltip_text = tooltip

func _on_icon_button_up():
	ItemClicked.emit(item)
