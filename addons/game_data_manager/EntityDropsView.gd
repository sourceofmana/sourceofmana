@tool
extends Control

var resources : Array[Resource] = []
var filteredResources : Array[Resource] = []
var selectedEntity : Resource = null
var itemCache : Dictionary = {}

@onready var entityList : ItemList = $VBoxContainer/HSplitContainer/EntityList
@onready var searchField : LineEdit = $VBoxContainer/TopBar/SearchField
@onready var entityLabel : Label = $VBoxContainer/HSplitContainer/DropsPanel/VBoxContainer/TopBar/EntityLabel
@onready var dropsContainer : VBoxContainer = $VBoxContainer/HSplitContainer/DropsPanel/VBoxContainer/ScrollContainer/DropsContainer

func _ready():
	if not GameDataUtil.is_part_of_edited_scene(self):
		LoadResources()
		RefreshEntityList()

func LoadResources():
	resources.clear()
	itemCache.clear()

	if DirAccess.dir_exists_absolute(Path.EntityPst):
		for resourcePath in FileSystem.ParseResources(Path.EntityPst):
			var loadedResource : Resource = FileSystem.LoadResource(resourcePath, false)
			if loadedResource is EntityData:
				var entity : EntityData = loadedResource as EntityData
				resources.push_back(entity)

	if DirAccess.dir_exists_absolute(Path.ItemPst):
		for resourcePath in FileSystem.ParseResources(Path.ItemPst):
			var cell : ItemCell = FileSystem.LoadResource(resourcePath, false)
			if cell and cell.name:
				itemCache[cell.name.hash()] = cell

func RefreshEntityList():
	ApplyFilter()
	PopulateEntityList()

func ApplyFilter():
	var query : String = searchField.text.to_lower()

	if query.is_empty():
		filteredResources = resources.duplicate()
	else:
		filteredResources.clear()
		for resource in resources:
			if resource.get("_name") and str(resource._name).to_lower().contains(query):
				filteredResources.push_back(resource)

func PopulateEntityList():
	entityList.clear()
	for resource in filteredResources:
		entityList.add_item(resource._name if resource.get("_name") else "Unnamed")
		var idx : int = entityList.item_count - 1
		entityList.set_item_metadata(idx, resource)
		var dropsArray : PackedInt64Array = resource.get("_drops")
		if not dropsArray or dropsArray.is_empty():
			entityList.set_item_custom_fg_color(idx, Color.LIGHT_SLATE_GRAY)

func _on_entity_selected(index : int):
	selectedEntity = entityList.get_item_metadata(index)
	if selectedEntity:
		entityLabel.text = selectedEntity._name + " - Drops"
		RefreshDropsDisplay()

func RefreshDropsDisplay():
	for child in dropsContainer.get_children():
		child.queue_free()

	if not selectedEntity:
		return

	var dropsArray : PackedInt64Array = selectedEntity.get("_drops")
	var dropsProba : Dictionary = selectedEntity.get("_dropsProba")

	if not dropsArray or dropsArray.is_empty():
		var noDropsLabel : Label = Label.new()
		noDropsLabel.text = "No drops configured. Click 'Add Drop' to add one."
		dropsContainer.add_child(noDropsLabel)
		return

	for i in dropsArray.size():
		var itemId : int = dropsArray[i]
		var probability : float = dropsProba.get(itemId, 1.0) if dropsProba else 1.0
		CreateDropWidget(itemId, probability, i)

func CreateDropWidget(itemId : int, probability : float, index : int):
	var hbox : HBoxContainer = HBoxContainer.new()

	var iconRect : TextureRect = TextureRect.new()
	iconRect.custom_minimum_size = Vector2(32, 32)
	iconRect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	iconRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var itemCell : ItemCell = itemCache.get(itemId)
	if itemCell and itemCell.icon:
		iconRect.texture = itemCell.icon

	hbox.add_child(iconRect)

	var itemNameEdit : LineEdit = LineEdit.new()
	itemNameEdit.custom_minimum_size = Vector2(150, 0)
	itemNameEdit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if itemCell:
		itemNameEdit.text = itemCell.name
	itemNameEdit.placeholder_text = "Item name"
	itemNameEdit.set_meta("drop_index", index)
	itemNameEdit.text_submitted.connect(_on_drop_item_changed.bind(index))
	hbox.add_child(itemNameEdit)

	var probLabel : Label = Label.new()
	probLabel.text = "Probability:"
	hbox.add_child(probLabel)

	var probSpin : SpinBox = SpinBox.new()
	probSpin.min_value = 0
	probSpin.max_value = 100
	probSpin.step = 0.1
	probSpin.value = probability
	probSpin.suffix = "%"
	probSpin.custom_minimum_size = Vector2(100, 0)
	probSpin.set_meta("drop_index", index)
	probSpin.value_changed.connect(_on_drop_probability_changed.bind(index))
	hbox.add_child(probSpin)

	var deleteBtn : Button = Button.new()
	deleteBtn.text = "X"
	deleteBtn.set_meta("drop_index", index)
	deleteBtn.pressed.connect(_on_delete_drop_pressed.bind(index))
	hbox.add_child(deleteBtn)

	dropsContainer.add_child(hbox)

func _on_drop_item_changed(newName : String, index : int):
	if not selectedEntity:
		return

	var dropsArray : PackedInt64Array = selectedEntity.get("_drops")
	var dropsProba : Dictionary = selectedEntity.get("_dropsProba")
	if not dropsArray or index >= dropsArray.size():
		return

	var itemCell : ItemCell = FindItemByName(newName)
	if itemCell:
		var oldItemId : int = dropsArray[index]
		var oldProb : float = dropsProba.get(oldItemId, 1.0) if dropsProba else 1.0

		dropsArray[index] = itemCell.id

		if not dropsProba:
			dropsProba = {}
			selectedEntity.set("_dropsProba", dropsProba)

		if dropsProba.has(oldItemId):
			dropsProba.erase(oldItemId)
		dropsProba[itemCell.id] = oldProb

		SaveEntity()
		RefreshDropsDisplay()

func _on_drop_probability_changed(newValue : float, index : int):
	if not selectedEntity:
		return

	var dropsArray : PackedInt64Array = selectedEntity.get("_drops")
	var dropsProba : Dictionary = selectedEntity.get("_dropsProba")
	if not dropsArray or index >= dropsArray.size():
		return

	var itemId : int = dropsArray[index]

	if not dropsProba:
		dropsProba = {}
		selectedEntity.set("_dropsProba", dropsProba)

	dropsProba[itemId] = newValue
	SaveEntity()

func _on_delete_drop_pressed(index : int):
	if not selectedEntity:
		return

	var dropsArray : PackedInt64Array = selectedEntity.get("_drops")
	var dropsProba : Dictionary = selectedEntity.get("_dropsProba")
	if not dropsArray or index >= dropsArray.size():
		return

	var itemId : int = dropsArray[index]

	dropsArray.remove_at(index)

	if dropsProba and dropsProba.has(itemId):
		dropsProba.erase(itemId)

	SaveEntity()
	RefreshDropsDisplay()

func _on_add_drop_pressed():
	if not selectedEntity:
		return

	var dropsArray : PackedInt64Array = selectedEntity.get("_drops")
	var dropsProba : Dictionary = selectedEntity.get("_dropsProba")

	if not dropsArray:
		dropsArray = PackedInt64Array()
		selectedEntity.set("_drops", dropsArray)

	if not dropsProba:
		dropsProba = {}
		selectedEntity.set("_dropsProba", dropsProba)

	dropsArray.append(0)
	dropsProba[0] = 1.0

	SaveEntity()
	RefreshDropsDisplay()

func FindItemByName(itemName : String) -> ItemCell:
	for itemCell : ItemCell in itemCache.values():
		if itemCell.name.to_lower() == itemName.to_lower():
			return itemCell
	return null

func SaveEntity():
	if not selectedEntity:
		return
	GameDataUtil.SaveResource(selectedEntity)

func _on_search_changed(_newText : String):
	RefreshEntityList()

func _on_refresh_pressed():
	LoadResources()
	RefreshEntityList()
	if selectedEntity:
		RefreshDropsDisplay()
