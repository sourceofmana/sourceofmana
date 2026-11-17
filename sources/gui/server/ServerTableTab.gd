extends ServerTab
class_name ServerTableTab

#
const DatabaseRefreshTicks : int			= 5
@onready var box : VBoxContainer			= $VBox
var tables : Dictionary[String, TableView]	= {}

#
func CanRefresh() -> bool:
	return Launcher.SQL != null and Launcher.SQL.isInitialized

func AddLabel(text : String) -> Label:
	var label : Label = Label.new()
	label.text = text
	label.theme_type_variation = &"ValueLabel"
	box.add_child(label)
	return label

func FillTable(title : String, header : PackedStringArray, rows : Array) -> TableView:
	var table : TableView = tables.get(title, null)
	if not table:
		AddLabel(title)
		table = TableView.new(header)
		box.add_child(table)
		tables[title] = table
	table.SetRows(rows)
	return table

#
func _init():
	refreshTicks = DatabaseRefreshTicks
