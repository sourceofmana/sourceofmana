@tool
extends ItemList

func _ready():
	refresh()

func refresh():
	clear()
	var location = "res://data/items"
	var dir = DirAccess.open(location)
	for file in dir.get_files():
		if file.ends_with(".tres"):
			var resource = ResourceLoader.load(location + "/" + file)
			var id = add_item(resource.name, resource.icon)
			set_item_tooltip(id, resource.description)
			set_item_metadata(id, resource.resource_path)

func _on_item_clicked(index, at_position, mouse_button_index):
	var resource_path = get_item_metadata(index)
	EditorInterface.edit_resource(ResourceLoader.load(resource_path))
