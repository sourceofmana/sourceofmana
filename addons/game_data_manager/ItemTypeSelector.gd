@tool
extends MenuButton

var selection = 0
var OPTIONS = [
	["BaseItem", BaseItem],
	["FoodItem", FoodItem]
]

var popup = get_popup()

func _ready():
	if PluginUtil.is_part_of_edited_scene(self):
		return
	icon = EditorInterface.get_editor_theme().get_icon("ArrowDown", "EditorIcons")
	popup.connect("index_pressed", _on_select)
	popup.clear()
	for option in OPTIONS:
		popup.add_radio_check_item(option[0], -1)
	_on_select(0)

func _on_select(index: int):
	selection = index
	text = "Type: " + OPTIONS[selection][0]
	for i in range(0, OPTIONS.size()):
		popup.set_item_checked(i, false)
	popup.set_item_checked(index, true)

func get_value():
	return OPTIONS[selection][1]
