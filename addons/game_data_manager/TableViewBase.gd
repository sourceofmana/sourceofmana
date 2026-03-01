@tool
class_name TableViewBase
extends Control

#
var resources : Array[Resource] = []
var filteredResources : Array[Resource] = []

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
