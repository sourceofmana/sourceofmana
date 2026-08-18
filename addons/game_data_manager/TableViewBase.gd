@tool
class_name TableViewBase
extends Control

#
var resources : Array[Resource] = []
var filteredResources : Array[Resource] = []
var sortColumn : int = -1
var sortAscending : bool = true

#
@onready var tree : Tree = $VBoxContainer/ScrollContainer/Tree
@onready var searchField : LineEdit = $VBoxContainer/TopBar/SearchField
@onready var itemCountLabel : Label = $VBoxContainer/TopBar/ItemCount

#
func _ready():
	if not GameDataUtil.is_part_of_edited_scene(self):
		Setup()
		LoadResources()
		RefreshTable()

# Override to return the directory path to scan for resources
func GetResourcePath() -> String:
	return ""

# Override to return true if this resource should be included
func IsValidResource(_resource : Resource) -> bool:
	return false

# Override to return the display name used for filtering
func GetResourceName(_resource : Resource) -> String:
	return ""

# Override to customize the count label text
func GetCountText(filtered : int, total : int) -> String:
	return "%d / %d" % [filtered, total]

# Override to set up tree columns and other UI before resources load
func Setup():
	pass

# Override to populate a single tree item from a resource
func UpdateTreeItem(_item : TreeItem, _resource : Resource):
	pass

# Override to return the sortable value for a resource at a given column index
func GetSortValue(_resource : Resource, _column : int) -> Variant:
	return null

# Override to return the unadorned title for each column, used to rebuild titles with sort arrows
func GetColumnNames() -> Array[String]:
	return []

#
func LoadResources():
	resources.clear()
	var path : String = GetResourcePath()
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		return
	for resourcePath in FileSystem.ParseResources(path):
		var loaded : Resource = FileSystem.LoadResource(resourcePath, false)
		if IsValidResource(loaded):
			resources.push_back(loaded)

func RefreshTable():
	ApplyFilter()
	ApplySort()
	PopulateTree()

func ApplyFilter():
	var query : String = searchField.text.to_lower()
	if query.is_empty():
		filteredResources = resources.duplicate()
	else:
		filteredResources.clear()
		for resource in resources:
			if GetResourceName(resource).to_lower().contains(query):
				filteredResources.push_back(resource)

func ApplySort():
	if sortColumn < 0:
		return

	filteredResources.sort_custom(func(a : Resource, b : Resource) -> bool:
		return CompareSortValues(GetSortValue(a, sortColumn), GetSortValue(b, sortColumn))
	)

func CompareSortValues(valA : Variant, valB : Variant) -> bool:
	var numA : Variant = ToComparableFloat(valA)
	var numB : Variant = ToComparableFloat(valB)
	if numA != null and numB != null:
		return numA < numB if sortAscending else numA > numB

	var strA : String = str(valA).to_lower()
	var strB : String = str(valB).to_lower()
	return strA < strB if sortAscending else strA > strB

func ToComparableFloat(value : Variant) -> Variant:
	if value is int or value is float:
		return float(value)
	if value is String and value.is_valid_float():
		return value.to_float()
	return null

func UpdateColumnTitles():
	var names : Array[String] = GetColumnNames()
	var arrow : String = " ▼" if not sortAscending else " ▲"
	for i in names.size():
		tree.set_column_title(i, names[i] + (arrow if i == sortColumn else ""))

func _on_column_clicked(column : int, _mouseButtonIdx : int):
	if sortColumn == column:
		sortAscending = not sortAscending
	else:
		sortColumn = column
		sortAscending = true

	UpdateColumnTitles()
	RefreshTable()

func PopulateTree():
	tree.clear()
	var root : TreeItem = tree.create_item()
	for resource in filteredResources:
		var item : TreeItem = tree.create_item(root)
		UpdateTreeItem(item, resource)
	if itemCountLabel:
		itemCountLabel.text = GetCountText(filteredResources.size(), resources.size())

#
func _on_search_changed(_newText : String):
	RefreshTable()

func _on_refresh_pressed():
	LoadResources()
	RefreshTable()
