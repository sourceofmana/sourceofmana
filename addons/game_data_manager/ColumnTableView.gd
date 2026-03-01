@tool
class_name ColumnTableView
extends TableViewBase

#
var sortColumn : int = 0
var sortAscending : bool = true
var enumPopup : PopupMenu = null
var editingItem : TreeItem = null
var editingColumn : int = -1

#
@onready var columnFilter : OptionButton = $VBoxContainer/TopBar/ColumnFilter

# Override to return the column definitions for this view
func GetColumns() -> Array[Dictionary]:
	return []

# Override to convert an enum type name + int value to a display string
func GetEnumName(_enumType : String, _value : int) -> String:
	return "UNKNOWN"

# Override to convert an enum type name + string key to an int value
func GetEnumValue(_enumType : String, _enumKey : String) -> int:
	return 0

# Override to fill the enum popup for a given column's enum type
func PopulateEnumPopup(_enumType : String, _currentValue : int):
	pass

# Override to create and configure the enum popup (pre-populate if needed)
func SetupEnumPopup():
	enumPopup = PopupMenu.new()
	add_child(enumPopup)
	enumPopup.id_pressed.connect(_on_enum_selected)

# Override for save-time processing after a property is set (e.g. recomputing derived fields)
func OnPropertySet(_resource : Resource, _col : Dictionary, _newValue : Variant):
	pass

# Override to provide the sort/filter value for a resource property
# Default just calls resource.get(property)
func GetPropertyValue(resource : Resource, property : String) -> Variant:
	return resource.get(property)

# Override to handle column-specific buttons beyond is_action
# Return true if the button was handled, false to fall through to default inspector
func HandleSpecialButton(_resource : Resource, _item : TreeItem, _column : int, _buttonId : int, _col : Dictionary) -> bool:
	return false

#
func Setup():
	var cols : Array[Dictionary] = GetColumns()
	tree.clear()
	tree.columns = cols.size()
	tree.hide_root = true
	tree.column_titles_visible = true
	tree.select_mode = Tree.SELECT_ROW

	for i in cols.size():
		var col : Dictionary = cols[i]
		tree.set_column_title(i, col.name)
		tree.set_column_expand(i, true)
		tree.set_column_custom_minimum_width(i, col.width)
		tree.set_column_expand_ratio(i, col.width / 100.0 if col.width > 100 else 0.5)

	columnFilter.clear()
	columnFilter.add_item("All Fields", -1)
	for i in cols.size():
		columnFilter.add_item(cols[i].name, i)

	SetupEnumPopup()

func RefreshTable():
	ApplyFilter()
	ApplySort()
	PopulateTree()

func ApplyFilter():
	var cols : Array[Dictionary] = GetColumns()
	var query : String = searchField.text.to_lower()
	var columnIdx : int = columnFilter.selected - 1

	if query.is_empty():
		filteredResources = resources.duplicate()
	else:
		filteredResources.clear()
		for resource in resources:
			if MatchFilter(resource, query, columnIdx, cols):
				filteredResources.push_back(resource)

func MatchFilter(resource : Resource, query : String, columnIdx : int, cols : Array[Dictionary]) -> bool:
	if columnIdx == -1:
		for col : Dictionary in cols:
			var value : Variant = GetPropertyValue(resource, col.property)
			if str(value).to_lower().contains(query):
				return true
		return false
	else:
		var col : Dictionary = cols[columnIdx]
		var value : Variant = GetPropertyValue(resource, col.property)
		return str(value).to_lower().contains(query)

func ApplySort():
	var cols : Array[Dictionary] = GetColumns()
	if sortColumn < 0 or sortColumn >= cols.size():
		return

	var col : Dictionary = cols[sortColumn]
	var property : String = col.property

	filteredResources.sort_custom(func(a : Resource, b : Resource) -> bool:
		var valA : Variant = GetPropertyValue(a, property)
		var valB : Variant = GetPropertyValue(b, property)

		if valA == null and valB == null:
			return false
		if valA == null:
			return not sortAscending
		if valB == null:
			return sortAscending

		if typeof(valA) == TYPE_OBJECT or typeof(valB) == TYPE_OBJECT:
			if valA is CellModifier or valB is CellModifier:
				var strA : String = GameDataUtil.FormatModifiers(valA) if valA is CellModifier else ""
				var strB : String = GameDataUtil.FormatModifiers(valB) if valB is CellModifier else ""
				return strA < strB if sortAscending else strA > strB
			else:
				return str(valA) < str(valB) if sortAscending else str(valA) > str(valB)

		if typeof(valA) == typeof(valB):
			return valA < valB if sortAscending else valA > valB
		return str(valA) < str(valB) if sortAscending else str(valA) > str(valB)
	)

#
func _on_column_clicked(column : int, _mouseButtonIdx : int):
	var cols : Array[Dictionary] = GetColumns()
	if sortColumn == column:
		sortAscending = not sortAscending
	else:
		sortColumn = column
		sortAscending = true

	for i in cols.size():
		var title : String = cols[i].name
		if i == sortColumn:
			title += " ▼" if not sortAscending else " ▲"
		tree.set_column_title(i, title)

	RefreshTable()

func _on_item_edited():
	var cols : Array[Dictionary] = GetColumns()
	var item : TreeItem = tree.get_edited()
	var column : int = tree.get_edited_column()
	var resource : Resource = item.get_metadata(0)

	if not resource or column >= cols.size():
		return

	var col : Dictionary = cols[column]
	if not col.editable:
		return

	var newValue : Variant
	match col.type:
		TYPE_BOOL:
			newValue = item.is_checked(column)
		TYPE_INT:
			if col.has("is_enum") and col.is_enum:
				newValue = GetEnumValue(col.get("enum_name", ""), item.get_text(column))
			else:
				newValue = item.get_text(column).to_int()
		TYPE_FLOAT:
			newValue = item.get_text(column).to_float()
		_:
			newValue = item.get_text(column)

	resource.set(col.property, newValue)
	OnPropertySet(resource, col, newValue)
	GameDataUtil.SaveResource(resource)

func _on_item_activated():
	var cols : Array[Dictionary] = GetColumns()
	var selected : TreeItem = tree.get_selected()
	if not selected:
		return

	var column : int = tree.get_selected_column()
	if column < 0 or column >= cols.size():
		return

	var col : Dictionary = cols[column]
	if col.has("is_enum") and col.is_enum and col.editable:
		editingItem = selected
		editingColumn = column

		var resource : Resource = selected.get_metadata(0)
		var currentValue : int = resource.get(col.property)

		PopulateEnumPopup(col.get("enum_name", ""), currentValue)
		enumPopup.position = get_viewport().get_mouse_position()
		enumPopup.popup()

func _on_enum_selected(id : int):
	var cols : Array[Dictionary] = GetColumns()
	if not editingItem or editingColumn < 0:
		return

	var resource : Resource = editingItem.get_metadata(0)
	var col : Dictionary = cols[editingColumn]

	resource.set(col.property, id)
	editingItem.set_text(editingColumn, GetEnumName(col.get("enum_name", ""), id))
	GameDataUtil.SaveResource(resource)

	editingItem = null
	editingColumn = -1

func _on_button_clicked(item : TreeItem, column : int, buttonId : int, _mouseButtonIndex : int):
	var cols : Array[Dictionary] = GetColumns()
	var resource : Resource = item.get_metadata(0)
	if not resource:
		return

	if buttonId >= 0 and buttonId < cols.size():
		var col : Dictionary = cols[buttonId]

		if col.has("is_action") and col.is_action:
			EditorInterface.edit_resource(resource)
			EditorInterface.inspect_object(resource)
			return

		if HandleSpecialButton(resource, item, column, buttonId, col):
			return

	EditorInterface.edit_resource(resource)
	EditorInterface.inspect_object(resource)

func ExportCsv(filename : String):
	var cols : Array[Dictionary] = GetColumns()
	var csvContent : String = ""

	var headers : Array[String] = []
	for col : Dictionary in cols:
		headers.push_back(col.name)
	csvContent += ",".join(headers) + "\n"

	for resource in filteredResources:
		var row : Array[String] = []
		for col : Dictionary in cols:
			var value : Variant = resource.get(col.property) if resource.get(col.property) != null else resource.get_meta(col.property, "")

			var cellValue : String = ""
			if col.has("is_enum") and col.is_enum and col.type == TYPE_INT:
				cellValue = GetEnumName(col.get("enum_name", ""), value)
			else:
				cellValue = str(value).replace('"', '""')

			if "," in cellValue or "\n" in cellValue:
				cellValue = '"' + cellValue + '"'

			row.push_back(cellValue)

		csvContent += ",".join(row) + "\n"

	var file : FileAccess = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(csvContent)
		file.close()

		var dialog : AcceptDialog = AcceptDialog.new()
		dialog.dialog_text = "Exported to:\n" + ProjectSettings.globalize_path(filename)
		dialog.title = "Export Complete"
		add_child(dialog)
		dialog.popup_centered()
		dialog.confirmed.connect(func(): dialog.queue_free())
	else:
		printerr("Failed to create export file")
