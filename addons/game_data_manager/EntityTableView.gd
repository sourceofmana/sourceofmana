@tool
extends ColumnTableView

#
const COLUMNS : Array[Dictionary] = [
	{ "name" : "Name", "property" : "_name", "type" : TYPE_STRING, "editable" : true, "width" : 150 },
	{ "name" : "Parent", "property" : "_parent", "type" : TYPE_OBJECT, "editable" : false, "width" : 120 },
	{ "name" : "Sprite", "property" : "_spritePreset", "type" : TYPE_STRING, "editable" : true, "width" : 120 },
	{ "name" : "Collision", "property" : "_collision", "type" : TYPE_STRING, "editable" : true, "width" : 100 },
	{ "name" : "Radius", "property" : "_radius", "type" : TYPE_INT, "editable" : true, "width" : 70 },
	{ "name" : "Display Name", "property" : "_displayName", "type" : TYPE_BOOL, "editable" : true, "width" : 100 },
	{ "name" : "Direction", "property" : "_direction", "type" : TYPE_INT, "editable" : true, "width" : 90, "is_enum" : true, "enum_name" : "Direction" },
	{ "name" : "State", "property" : "_state", "type" : TYPE_INT, "editable" : true, "width" : 90, "is_enum" : true, "enum_name" : "State" },
	{ "name" : "Behaviour", "property" : "_behaviour", "type" : TYPE_INT, "editable" : false, "width" : 200, "is_bitflags" : true },
	{ "name" : "Edit", "property" : "_edit", "type" : TYPE_NIL, "editable" : false, "width" : 60, "is_action" : true },
]

var behaviourDialog : Window = null

#
func GetColumns() -> Array[Dictionary]:
	return COLUMNS

func GetResourcePath() -> String:
	return Path.EntityPst

func IsValidResource(resource : Resource) -> bool:
	return resource is EntityData

func GetResourceName(resource : Resource) -> String:
	return str(resource.get("_name")) if resource.get("_name") else ""

func GetCountText(filtered : int, total : int) -> String:
	return "%d / %d entities" % [filtered, total]

func GetEnumName(enumType : String, value : int) -> String:
	match enumType:
		"Direction":
			for key in ActorCommons.Direction.keys():
				if ActorCommons.Direction[key] == value:
					return key
			return "UNKNOWN"
		"State":
			for key in ActorCommons.State.keys():
				if ActorCommons.State[key] == value:
					return key
			return "UNKNOWN"
	return "UNKNOWN"

func GetEnumValue(enumType : String, enumKey : String) -> int:
	match enumType:
		"Direction":
			return ActorCommons.Direction.get(enumKey.to_upper(), ActorCommons.Direction.UNKNOWN)
		"State":
			return ActorCommons.State.get(enumKey.to_upper(), ActorCommons.State.UNKNOWN)
	return 0

func PopulateEnumPopup(enumType : String, currentValue : int):
	enumPopup.clear()
	match enumType:
		"Direction":
			for key in ActorCommons.Direction.keys():
				enumPopup.add_item(key, ActorCommons.Direction[key])
		"State":
			for key in ActorCommons.State.keys():
				enumPopup.add_item(key, ActorCommons.State[key])

	for i in enumPopup.item_count:
		var itemId : int = enumPopup.get_item_id(i)
		enumPopup.set_item_checked(i, itemId == currentValue)

func OnPropertySet(resource : Resource, col : Dictionary, newValue : Variant):
	if col.property == "_name":
		resource._id = newValue.hash()

func HandleSpecialButton(resource : Resource, item : TreeItem, column : int, _buttonId : int, col : Dictionary) -> bool:
	if col.has("is_bitflags") and col.is_bitflags:
		ShowBehaviourEditor(resource, item, column)
		return true
	return false

func UpdateTreeItem(item : TreeItem, resource : Resource):
	for i in COLUMNS.size():
		var col : Dictionary = COLUMNS[i]

		if col.has("is_action") and col.is_action:
			item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), i, false, "Edit Entity")
			continue

		var value : Variant = resource.get(col.property)

		match col.type:
			TYPE_BOOL:
				item.set_cell_mode(i, TreeItem.CELL_MODE_CHECK)
				item.set_checked(i, value if value != null else false)
				item.set_editable(i, col.editable)
			TYPE_INT:
				if col.has("is_bitflags") and col.is_bitflags:
					var flagsText : String = GetBehaviourFlagsText(value)
					item.set_text(i, flagsText)
					item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), i, false, "Edit Behaviour Flags")
					item.set_editable(i, false)
				elif col.has("is_enum") and col.is_enum:
					var enumName : String = GetEnumName(col.enum_name, value)
					item.set_text(i, enumName)
					item.set_editable(i, false)
				else:
					item.set_text(i, str(value))
					item.set_editable(i, col.editable)
			TYPE_FLOAT:
				item.set_text(i, "%.2f" % value if value != null else "0.00")
				item.set_editable(i, col.editable)
			TYPE_OBJECT:
				if value and value is EntityData:
					item.set_text(i, value._name)
				else:
					item.set_text(i, "")
				item.set_editable(i, col.editable)
			_:
				item.set_text(i, str(value) if value != null else "")
				item.set_editable(i, col.editable)

		if i == 0:
			item.set_metadata(0, resource)

func GetBehaviourFlagsText(flags : int) -> String:
	if flags == AICommons.Behaviour.NONE:
		return "None"

	var flagNames : Array[String] = []
	for key : String in AICommons.Behaviour.keys():
		if key == "NONE":
			continue
		var flagValue : int = AICommons.Behaviour[key]
		if flags & flagValue:
			flagNames.push_back(key)

	return ", ".join(flagNames) if not flagNames.is_empty() else "None"

func ShowBehaviourEditor(resource : Resource, item : TreeItem, column : int):
	if behaviourDialog:
		behaviourDialog.queue_free()

	behaviourDialog = Window.new()
	behaviourDialog.title = "Edit Behaviour Flags - " + resource._name
	behaviourDialog.size = Vector2i(300, 400)
	behaviourDialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN

	var vbox : VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	behaviourDialog.add_child(vbox)

	var scroll : ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var checkboxContainer : VBoxContainer = VBoxContainer.new()
	scroll.add_child(checkboxContainer)

	var currentFlags : int = resource.get("_behaviour")
	if currentFlags == null:
		currentFlags = AICommons.Behaviour.NONE

	var checkboxes : Dictionary = {}
	for key in AICommons.Behaviour.keys():
		if key == "NONE":
			continue

		var flagValue : int = AICommons.Behaviour[key]
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = key
		checkbox.button_pressed = (currentFlags & flagValue) != 0
		checkbox.set_meta("flag_value", flagValue)
		checkboxContainer.add_child(checkbox)
		checkboxes[key] = checkbox

	var buttonBox : HBoxContainer = HBoxContainer.new()
	buttonBox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(buttonBox)

	var cancelBtn : Button = Button.new()
	cancelBtn.text = "Cancel"
	cancelBtn.pressed.connect(behaviourDialog.queue_free)
	buttonBox.add_child(cancelBtn)

	var applyBtn : Button = Button.new()
	applyBtn.text = "Apply"
	applyBtn.pressed.connect(func():
		var newFlags : int = AICommons.Behaviour.NONE
		for cbKey in checkboxes:
			var checkbox : CheckBox = checkboxes[cbKey]
			if checkbox.button_pressed:
				newFlags |= checkbox.get_meta("flag_value")

		resource.set("_behaviour", newFlags)

		var flagsText : String = GetBehaviourFlagsText(newFlags)
		item.set_text(column, flagsText)

		GameDataUtil.SaveResource(resource)

		behaviourDialog.queue_free()
	)
	buttonBox.add_child(applyBtn)

	add_child(behaviourDialog)
	behaviourDialog.popup()

#
func _on_create_pressed():
	var dialog : ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Create New Entity"
	dialog.dialog_text = "Enter entity name:"

	var vbox : VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var input : LineEdit = LineEdit.new()
	input.placeholder_text = "Entity Name"
	vbox.add_child(input)

	add_child(dialog)
	dialog.popup_centered(Vector2(300, 100))

	dialog.confirmed.connect(func():
		var entityName : String = input.text.strip_edges()
		if entityName.is_empty():
			GameDataUtil.ShowErrorDialog(self,"Entity name cannot be empty!")
			dialog.queue_free()
			return

		var entity : EntityData = EntityData.new()
		entity._name = entityName

		var filename : String = entityName.replace(" ", "") + ".tres"
		var filepath : String = Path.EntityPst.path_join(filename)

		if FileAccess.file_exists(filepath):
			GameDataUtil.ShowErrorDialog(self,"Entity file already exists: " + filename)
			dialog.queue_free()
			return

		var error : int = ResourceSaver.save(entity, filepath)
		if error != OK:
			GameDataUtil.ShowErrorDialog(self,"Failed to save entity: " + str(error))
			dialog.queue_free()
			return

		LoadResources()
		RefreshTable()

		EditorInterface.edit_resource(entity)
		EditorInterface.inspect_object(entity)
		dialog.queue_free()
	)

	dialog.canceled.connect(dialog.queue_free)

func OnDeleteDialogueConfirmed(dialog : ConfirmationDialog, filepath : String):
	var dir : DirAccess = DirAccess.open(filepath.get_base_dir())
	if dir:
		var error : int = dir.remove(filepath)
		if error != OK:
			GameDataUtil.ShowErrorDialog(self,"Failed to delete file: " + str(error))
		else:
			LoadResources()
			RefreshTable()
	else:
		GameDataUtil.ShowErrorDialog(self,"Failed to access directory!")
	dialog.queue_free()

func _on_delete_pressed():
	var selected : TreeItem = tree.get_selected()
	if not selected:
		GameDataUtil.ShowErrorDialog(self,"No entity selected!")
		return

	var resource : Resource = selected.get_metadata(0)
	if not resource:
		return

	var filepath : String = resource.resource_path
	if not filepath or filepath.is_empty():
		GameDataUtil.ShowErrorDialog(self,"Cannot determine file path!")
		return

	var dialog : ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Delete Entity"
	dialog.dialog_text = "Are you sure you want to delete:\n" + resource._name + "\n\nFile: " + filepath + "\n\nThis cannot be undone!"
	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(OnDeleteDialogueConfirmed.bind(dialog, filepath))
	dialog.canceled.connect(dialog.queue_free)

func _on_export_csv_pressed():
	var timestamp : String = Time.get_datetime_string_from_system().replace(":", "-")
	ExportCsv("user://entities_export_" + timestamp + ".csv")
