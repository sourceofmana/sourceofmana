extends ColorRect
class_name InventoryItemGridTile

signal ItemClicked(InventoryItem)

var item : InventoryItem

func set_data(p_item: InventoryItem):
	item = p_item
	$Icon.set_normal_texture(item.type.icon)
	if item.count >= 1000:
		$Label.text = "999+"
	elif item.count <= 1:
		$Label.text = ""
	else:
		$Label.text = str(item.count)
	


func _on_icon_button_up():
	emit_signal('ItemClicked', item)
