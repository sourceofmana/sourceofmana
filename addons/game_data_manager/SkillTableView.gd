@tool
extends ColumnTableView

#
const COLUMNS : Array[Dictionary] = [
	{ "name" : "Name", "property" : "name", "type" : TYPE_STRING, "editable" : true, "width" : 150 },
	{ "name" : "Category", "property" : "category", "type" : TYPE_INT, "editable" : true, "width" : 100, "is_enum" : true, "enum_name" : "Category" },
	{ "name" : "State", "property" : "state", "type" : TYPE_INT, "editable" : true, "width" : 100, "is_enum" : true, "enum_name" : "State" },
	{ "name" : "Range", "property" : "cellRange", "type" : TYPE_INT, "editable" : true, "width" : 80 },
	{ "name" : "Mode", "property" : "mode", "type" : TYPE_INT, "editable" : true, "width" : 100, "is_enum" : true, "enum_name" : "Mode" },
	{ "name" : "Repeat", "property" : "repeat", "type" : TYPE_BOOL, "editable" : true, "width" : 70 },
	{ "name" : "Usable", "property" : "usable", "type" : TYPE_BOOL, "editable" : true, "width" : 70 },
	{ "name" : "Cooldown", "property" : "cooldownTime", "type" : TYPE_FLOAT, "editable" : true, "width" : 80 },
	{ "name" : "Cast Time", "property" : "castTime", "type" : TYPE_FLOAT, "editable" : true, "width" : 80 },
	{ "name" : "Skill Time", "property" : "skillTime", "type" : TYPE_FLOAT, "editable" : true, "width" : 80 },
	{ "name" : "Modifiers", "property" : "modifiers", "type" : TYPE_OBJECT, "editable" : false, "width" : 250, "is_modifiers" : true },
	{ "name" : "Description", "property" : "description", "type" : TYPE_STRING, "editable" : true, "width" : 250 },
	{ "name" : "Icon", "property" : "icon", "type" : TYPE_OBJECT, "editable" : false, "width" : 60 },
	{ "name" : "Edit", "property" : "_edit", "type" : TYPE_NIL, "editable" : false, "width" : 60, "is_action" : true },
]

#
func GetColumns() -> Array[Dictionary]:
	return COLUMNS

func GetResourcePath() -> String:
	return Path.SkillPst

func IsValidResource(resource : Resource) -> bool:
	return resource is SkillCell

func GetResourceName(resource : Resource) -> String:
	return str(resource.get("name")) if resource.get("name") else ""

func GetCountText(filtered : int, total : int) -> String:
	return "%d / %d skills" % [filtered, total]

func GetEnumName(enumType : String, value : int) -> String:
	match enumType:
		"Category":
			for key in SkillCell.Category.keys():
				if SkillCell.Category[key] == value:
					return key
			return "UNKNOWN"
		"State":
			for key in ActorCommons.State.keys():
				if ActorCommons.State[key] == value:
					return key
			return "UNKNOWN"
		"Mode":
			for key in Skill.TargetMode.keys():
				if Skill.TargetMode[key] == value:
					return key
			return "UNKNOWN"
	return "UNKNOWN"

func GetEnumValue(enumType : String, enumKey : String) -> int:
	match enumType:
		"Category":
			return SkillCell.Category.get(enumKey.to_upper(), SkillCell.Category.SPELL)
		"State":
			return ActorCommons.State.get(enumKey.to_upper(), ActorCommons.State.UNKNOWN)
		"Mode":
			return Skill.TargetMode.get(enumKey.to_upper(), Skill.TargetMode.SINGLE)
	return 0

func PopulateEnumPopup(enumType : String, currentValue : int):
	enumPopup.clear()
	match enumType:
		"Category":
			for key in SkillCell.Category.keys():
				enumPopup.add_item(key, SkillCell.Category[key])
		"State":
			for key in ActorCommons.State.keys():
				enumPopup.add_item(key, ActorCommons.State[key])
		"Mode":
			for key in Skill.TargetMode.keys():
				enumPopup.add_item(key, Skill.TargetMode[key])

	for i in enumPopup.item_count:
		var itemId : int = enumPopup.get_item_id(i)
		enumPopup.set_item_checked(i, itemId == currentValue)

func HandleSpecialButton(resource : Resource, _item : TreeItem, _column : int, _buttonId : int, col : Dictionary) -> bool:
	if col.has("is_modifiers") and col.is_modifiers:
		var modifiers : Variant = resource.get("modifiers")
		if modifiers:
			EditorInterface.edit_resource(modifiers)
			EditorInterface.inspect_object(modifiers)
		return true
	return false

func UpdateTreeItem(item : TreeItem, resource : Resource):
	for i in COLUMNS.size():
		var col : Dictionary = COLUMNS[i]

		if col.has("is_action") and col.is_action:
			item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), i, false, "Edit Skill")
			continue

		var value : Variant
		if col.type == TYPE_OBJECT:
			value = resource.get(col.property)
		else:
			value = resource.get(col.property) if resource.get(col.property) != null else resource.get_meta(col.property, "")

		match col.type:
			TYPE_BOOL:
				item.set_cell_mode(i, TreeItem.CELL_MODE_CHECK)
				item.set_checked(i, value if value != null else false)
				item.set_editable(i, col.editable)
			TYPE_INT:
				if col.has("is_enum") and col.is_enum:
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
				if col.has("is_modifiers") and col.is_modifiers:
					var modifierText : String = GameDataUtil.FormatModifiers(value)
					item.set_text(i, modifierText)
					if value:
						item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), i, false, "Edit Modifiers")
					item.set_editable(i, false)
				elif value is Texture2D:
					item.set_icon(i, value)
					item.set_icon_max_width(i, 32)
					item.set_editable(i, false)
				else:
					item.set_text(i, str(value))
					item.set_editable(i, false)
			_:
				if col.has("clickable") and col.clickable:
					item.set_text(i, str(value) if value != null else "")
					item.add_button(i, EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons"), i, false, "Open in Inspector")
				else:
					item.set_text(i, str(value) if value != null else "")
					item.set_editable(i, col.editable)

		if i == 0:
			item.set_metadata(0, resource)

#
func _on_create_pressed():
	var dialog : ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Create New Skill"
	dialog.dialog_text = "Enter skill name:"

	var vbox : VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var nameInput : LineEdit = LineEdit.new()
	nameInput.placeholder_text = "Skill Name"
	vbox.add_child(nameInput)

	add_child(dialog)
	dialog.popup_centered(Vector2(300, 100))

	dialog.confirmed.connect(func():
		var skillName : String = nameInput.text.strip_edges()
		if skillName.is_empty():
			GameDataUtil.ShowErrorDialog(self,"Skill name cannot be empty!")
			dialog.queue_free()
			return

		var newSkill : SkillCell = SkillCell.new()
		newSkill.name = skillName
		newSkill.type = CellCommons.Type.SKILL

		var filename : String = skillName.replace(" ", "") + ".tres"
		var filepath : String = Path.SkillPst.path_join(filename)

		if FileAccess.file_exists(filepath):
			GameDataUtil.ShowErrorDialog(self,"Skill file already exists: " + filename)
			dialog.queue_free()
			return

		var error : int = ResourceSaver.save(newSkill, filepath)
		if error != OK:
			GameDataUtil.ShowErrorDialog(self,"Failed to save skill: " + str(error))
			dialog.queue_free()
			return

		LoadResources()
		RefreshTable()

		EditorInterface.edit_resource(newSkill)
		EditorInterface.inspect_object(newSkill)

		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

func _on_delete_pressed():
	var selected : TreeItem = tree.get_selected()
	if not selected:
		GameDataUtil.ShowErrorDialog(self,"No skill selected!")
		return

	var resource : Resource = selected.get_metadata(0)
	if not resource:
		return

	var filepath : String = resource.resource_path
	if not filepath or filepath.is_empty():
		GameDataUtil.ShowErrorDialog(self,"Cannot determine file path!")
		return

	var dialog : ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Delete Skill"
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
				RefreshTable()
		else:
			GameDataUtil.ShowErrorDialog(self,"Failed to access directory!")
		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

func _on_export_csv_pressed():
	var timestamp : String = Time.get_datetime_string_from_system().replace(":", "-")
	ExportCsv("user://skills_export_" + timestamp + ".csv")
