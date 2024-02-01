@tool
extends ItemList

const ITEMS_FOLDER = Path.ItemDataRsc

var resources: Array[Resource] = []

func _ready():
	if not PluginUtil.is_part_of_edited_scene(self):
		refresh()
		var inspector = EditorInterface.get_inspector()
		inspector.connect("property_edited", property_edited)
		inspector.get_edited_object()


func property_edited(_property: String):
	# Only update the resource that changed
	var inspected_object = EditorInterface.get_inspector().get_edited_object()
	if inspected_object and inspected_object.resource_path.contains(ITEMS_FOLDER):
		for i in resources.size():
			var resource = resources[i]
			print(resource.resource_path, inspected_object.resource_path)
			if resource.resource_path == inspected_object.resource_path:
				resources[i] = ResourceLoader.load(resource.resource_path)
				showResources()
				return

func refresh():
	load_resources()
	showResources()

func filterResource(resource: Resource, rawQuery: String):
	var query = rawQuery.to_lower()
	var nameMatches = resource.name.to_lower().contains(query)
	var descriptionMatches = resource.description.to_lower().contains(query)
	print(resource.name, query, nameMatches, descriptionMatches)
	return nameMatches || descriptionMatches

func showResources():
	var query = $"../HBoxContainer/LineEdit".text
	
	var filtered_resources: Array[Resource]
	if query.is_empty():
		filtered_resources = resources
	else:
		filtered_resources = resources.filter(func(r): return filterResource(r, query))
	
	clear()
	for resource in filtered_resources:
		var id = add_item(resource.name if resource.name else "[ Unconfigured Item ] " + resource.resource_path, resource.icon)
		set_item_tooltip(id, resource.description)
		set_item_metadata(id, resource.resource_path)

func load_resources():
	var new_resources: Array[Resource] = []
	var dir = DirAccess.open(ITEMS_FOLDER)
	for file in dir.get_files():
		if file.ends_with(".tres"):
			new_resources.push_back(ResourceLoader.load(ITEMS_FOLDER + "/" + file))
	resources = new_resources

func _on_item_clicked(index, at_position, mouse_button_index):
	var resource_path = get_item_metadata(index)
	EditorInterface.edit_resource(ResourceLoader.load(resource_path))

func _on_line_edit_text_changed(new_text):
	showResources()

#region create item

func alert(message: String):
	$"../HBoxContainer2/AcceptDialog".dialog_text = message
	$"../HBoxContainer2/AcceptDialog".popup_centered()

func _on_create_item_pressed():
	var textField: LineEdit = $"../HBoxContainer2/LineEdit"
	var text: String = textField.text
	
	if text.is_empty():
		alert("filename not set")
		return
	
	var filename: String

	if text.ends_with(".tres"):
		filename = text
	else:
		filename = text + ".tres"
	
	var item_type = $"../HBoxContainer2/ItemTypeSelector".get_value()
	var resource = item_type.new()
	
	var file_path = ITEMS_FOLDER + "/" + filename
	if FileAccess.file_exists(file_path):
		alert("Item exists already, choose a different filename")
		return
	
	var error = ResourceSaver.save(resource, file_path)
	if error != OK:
		printerr("error saving resource", file_path, error)
		alert("error saving resource, look in console for details")
		return
	
	EditorInterface.edit_resource(ResourceLoader.load(file_path))
	textField.text = ""
	refresh()
	$"../HBoxContainer/LineEdit".text = ""

#endregion
