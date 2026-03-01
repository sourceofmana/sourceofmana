@tool
extends ColumnTableView

#
const COLUMNS : Array[Dictionary] = [
	{ "name" : "Name", "property" : "name", "type" : TYPE_STRING, "editable" : true, "width" : 150 },
	{ "name" : "Slot", "property" : "slot", "type" : TYPE_INT, "editable" : true, "width" : 100, "is_enum" : true, "enum_class" : "ActorCommons.Slot" },
	{ "name" : "Weight", "property" : "weight", "type" : TYPE_FLOAT, "editable" : true, "width" : 80 },
	{ "name" : "Stackable", "property" : "stackable", "type" : TYPE_BOOL, "editable" : true, "width" : 80 },
	{ "name" : "Usable", "property" : "usable", "type" : TYPE_BOOL, "editable" : true, "width" : 80 },
	{ "name" : "Custom Field", "property" : "customfield", "type" : TYPE_STRING, "editable" : true, "width" : 120 },
	{ "name" : "Description", "property" : "description", "type" : TYPE_STRING, "editable" : true, "width" : 250 },
	{ "name" : "Modifiers", "property" : "modifiers", "type" : TYPE_OBJECT, "editable" : false, "width" : 250, "is_modifiers" : true },
	{ "name" : "Icon", "property" : "icon", "type" : TYPE_OBJECT, "editable" : false, "width" : 60 },
	{ "name" : "Edit", "property" : "_edit", "type" : TYPE_NIL, "editable" : false, "width" : 60, "is_action" : true },
]

var iconPreviewCache : Dictionary = {}

#
func GetColumns() -> Array[Dictionary]:
	return COLUMNS

func GetResourcePath() -> String:
	return Path.ItemPst

func IsValidResource(resource : Resource) -> bool:
	return resource is ItemCell

func GetResourceName(resource : Resource) -> String:
	return str(resource.get("name")) if resource.get("name") else ""

func GetCountText(filtered : int, total : int) -> String:
	return "%d / %d items" % [filtered, total]

# Pre-populate enum popup with all Slot values
func SetupEnumPopup():
	enumPopup = PopupMenu.new()
	add_child(enumPopup)

	for key in ActorCommons.Slot.keys():
		if not key.begins_with("FIRST_") and not key.begins_with("LAST_") and key != "COUNT":
			enumPopup.add_item(key, ActorCommons.Slot[key])

	enumPopup.id_pressed.connect(_on_enum_selected)

# Popup is pre-populated; just update the checkmark for the current value
func PopulateEnumPopup(_enumType : String, currentValue : int):
	for i in enumPopup.item_count:
		var itemId : int = enumPopup.get_item_id(i)
		enumPopup.set_item_checked(i, itemId == currentValue)

func GetEnumName(_enumType : String, value : int) -> String:
	return GetSlotName(value)

func GetEnumValue(_enumType : String, enumKey : String) -> int:
	return GetSlotValue(enumKey)

# Supports a virtual _filepath property that returns resource_path
func GetPropertyValue(resource : Resource, property : String) -> Variant:
	if property == "_filepath":
		return resource.resource_path
	return resource.get(property)

func HandleSpecialButton(resource : Resource, _item : TreeItem, _column : int, _buttonId : int, col : Dictionary) -> bool:
	if col.has("is_modifiers") and col.is_modifiers:
		var modifiers : Variant = resource.get("modifiers")
		if modifiers:
			EditorInterface.edit_resource(modifiers)
			EditorInterface.inspect_object(modifiers)
		return true
	return false

func GetSlotName(slotValue : int) -> String:
	for key in ActorCommons.Slot.keys():
		if ActorCommons.Slot[key] == slotValue:
			return key
	return "UNKNOWN"

func GetSlotValue(slotName : String) -> int:
	return ActorCommons.Slot.get(slotName.to_upper(), ActorCommons.Slot.NONE)

# Override _ready to await icon previews before first render
func _ready():
	if not GameDataUtil.is_part_of_edited_scene(self):
		Setup()
		LoadResources()
		await GenerateIconPreviews()
		RefreshTable()

func LoadResources():
	iconPreviewCache.clear()
	super.LoadResources()

func _on_refresh_pressed():
	LoadResources()
	await GenerateIconPreviews()
	RefreshTable()

func UpdateTreeItem(item : TreeItem, resource : Resource):
	for i in COLUMNS.size():
		var col : Dictionary = COLUMNS[i]

		if col.has("is_action") and col.is_action:
			item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), i, false, "Edit Item")
			continue

		var value : Variant
		if col.property == "_filepath":
			value = resource.resource_path
		else:
			value = resource.get(col.property)

		match col.type:
			TYPE_BOOL:
				item.set_cell_mode(i, TreeItem.CELL_MODE_CHECK)
				item.set_checked(i, value if value != null else false)
				item.set_editable(i, col.editable)
			TYPE_INT:
				if col.has("is_enum") and col.is_enum:
					var enumName : String = GetSlotName(value)
					item.set_text(i, enumName)
					item.set_editable(i, false)
				else:
					item.set_text(i, str(value))
					item.set_editable(i, col.editable)
			TYPE_FLOAT:
				item.set_text(i, "%.2f" % value if value != null else "0.00")
				item.set_editable(i, col.editable)
			TYPE_OBJECT:
				if col.has("is_modifiers") and col.is_modifiers:
					var modifierText : String = GameDataUtil.FormatModifiers(value)
					item.set_text(i, modifierText)
					if value:
						item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), i, false, "Edit Modifiers")
					item.set_editable(i, false)
				elif value is Texture2D:
					var cacheKey : String = resource.resource_path
					var iconToDisplay : Texture2D = iconPreviewCache.get(cacheKey, value)
					item.set_icon(i, iconToDisplay)
					item.set_icon_max_width(i, 32)
					item.set_editable(i, false)
				else:
					item.set_text(i, str(value))
					item.set_editable(i, false)
			_:
				if col.has("clickable") and col.clickable:
					item.set_text(i, str(value) if value != null else "")
					item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), -1, false, "Open in Inspector")
				else:
					item.set_text(i, str(value) if value != null else "")
					item.set_editable(i, col.editable)

		if i == 0:
			item.set_metadata(0, resource)

func GenerateIconPreviews():
	for resource in resources:
		var icon : Variant = resource.get("icon")
		var shader : Variant = resource.get("shader")
		if icon and shader and icon is Texture2D and shader is Material:
			var cacheKey : String = resource.resource_path
			await CreateMaterialPreview(icon, shader, cacheKey)

func CreateMaterialPreview(texture : Texture2D, material : Material, cacheKey : String) -> ImageTexture:
	if not texture or not material:
		return null

	if iconPreviewCache.has(cacheKey):
		return iconPreviewCache[cacheKey]

	var textureSize : Vector2 = texture.get_size()
	if textureSize.x == 0 or textureSize.y == 0:
		return null

	var viewport : SubViewport = SubViewport.new()
	viewport.size = textureSize
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.material = material
	sprite.centered = false

	add_child(viewport)
	viewport.add_child(sprite)

	await get_tree().process_frame
	await get_tree().process_frame

	var image : Image = viewport.get_texture().get_image()

	viewport.queue_free()

	if image:
		var resultTexture : ImageTexture = ImageTexture.create_from_image(image)
		iconPreviewCache[cacheKey] = resultTexture
		return resultTexture

	return null

#
func _on_create_pressed():
	var dialog : ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Create New Item"
	dialog.dialog_text = "Enter item name:"

	var vbox : VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var nameInput : LineEdit = LineEdit.new()
	nameInput.placeholder_text = "Item Name"
	vbox.add_child(nameInput)

	add_child(dialog)
	dialog.popup_centered(Vector2(300, 100))

	dialog.confirmed.connect(func():
		var itemName : String = nameInput.text.strip_edges()
		if itemName.is_empty():
			GameDataUtil.ShowErrorDialog(self,"Item name cannot be empty!")
			dialog.queue_free()
			return

		var newItem : ItemCell = ItemCell.new()
		newItem.name = itemName
		newItem.type = CellCommons.Type.ITEM

		var filename : String = itemName.replace(" ", "") + ".tres"
		var filepath : String = Path.ItemPst.path_join(filename)

		if FileAccess.file_exists(filepath):
			GameDataUtil.ShowErrorDialog(self,"Item file already exists: " + filename)
			dialog.queue_free()
			return

		var error : int = ResourceSaver.save(newItem, filepath)
		if error != OK:
			GameDataUtil.ShowErrorDialog(self,"Failed to save item: " + str(error))
			dialog.queue_free()
			return

		LoadResources()
		await GenerateIconPreviews()
		RefreshTable()

		EditorInterface.edit_resource(newItem)
		EditorInterface.inspect_object(newItem)

		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

func _on_delete_pressed():
	var selected : TreeItem = tree.get_selected()
	if not selected:
		GameDataUtil.ShowErrorDialog(self,"No item selected!")
		return

	var resource : Resource = selected.get_metadata(0)
	if not resource:
		return

	var filepath : String = resource.resource_path
	if not filepath or filepath.is_empty():
		GameDataUtil.ShowErrorDialog(self,"Cannot determine file path!")
		return

	var dialog : ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Delete Item"
	dialog.dialog_text = "Are you sure you want to delete:\n" + resource.name + "\n\nFile: " + filepath + "\n\nThis cannot be undone!"
	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		var dir : DirAccess = DirAccess.open(filepath.get_base_dir())
		if dir:
			var deleteError : int = dir.remove(filepath)
			if deleteError != OK:
				GameDataUtil.ShowErrorDialog(self,"Failed to delete file: " + str(deleteError))
			else:
				LoadResources()
				await GenerateIconPreviews()
				RefreshTable()
		else:
			GameDataUtil.ShowErrorDialog(self,"Failed to access directory!")
		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

func _on_export_csv_pressed():
	var timestamp : String = Time.get_datetime_string_from_system().replace(":", "-")
	ExportCsv("user://items_export_" + timestamp + ".csv")
