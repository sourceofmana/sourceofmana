@tool
extends TableViewBase

var EQUIPMENT_COLUMNS : Array[Dictionary] = []

#
func GetResourcePath() -> String:
	return Path.EntityPst

func IsValidResource(resource : Resource) -> bool:
	return resource is EntityData

func GetResourceName(resource : Resource) -> String:
	return str(resource.get("_name")) if resource.get("_name") else ""

func GetCountText(filtered : int, total : int) -> String:
	return "%d / %d entities" % [filtered, total]

func Setup():
	SetupEquipmentColumns()

	tree.clear()
	tree.columns = 1 + EQUIPMENT_COLUMNS.size()
	tree.hide_root = true
	tree.column_titles_visible = true
	tree.select_mode = Tree.SELECT_SINGLE

	tree.set_column_title(0, "Entity")
	tree.set_column_expand(0, true)
	tree.set_column_custom_minimum_width(0, 150)
	tree.set_column_expand_ratio(0, 1.5)

	for i in EQUIPMENT_COLUMNS.size():
		var columnIdx : int = i + 1
		tree.set_column_title(columnIdx, EQUIPMENT_COLUMNS[i].name)
		tree.set_column_expand(columnIdx, true)
		tree.set_column_custom_minimum_width(columnIdx, 100)
		tree.set_column_expand_ratio(columnIdx, 0.8)

func SetupEquipmentColumns():
	EQUIPMENT_COLUMNS.clear()
	for key in ActorCommons.Slot.keys():
		var value : int = ActorCommons.Slot[key]
		if value >= ActorCommons.Slot.FIRST_EQUIPMENT and value < ActorCommons.Slot.LAST_EQUIPMENT:
			EQUIPMENT_COLUMNS.push_back({ "name" : key, "value" : value })

func UpdateTreeItem(item : TreeItem, resource : Resource):
	item.set_text(0, resource._name if resource.get("_name") else "Unnamed")
	item.set_editable(0, false)
	item.set_metadata(0, resource)

	var equipmentArray : Array = resource.get("_equipment")

	for i in EQUIPMENT_COLUMNS.size():
		var columnIdx : int = i + 1
		var slotValue : int = EQUIPMENT_COLUMNS[i].value

		var itemName : String = GetEquippedItemName(equipmentArray, slotValue)

		item.set_text(columnIdx, itemName)
		item.set_editable(columnIdx, true)

func GetEquippedItemName(equipmentArray : Array, slot : int) -> String:
	if not equipmentArray or slot >= equipmentArray.size():
		return ""

	var itemCell : ItemCell = equipmentArray[slot]
	if itemCell:
		return itemCell.name

	return ""

#
func _on_item_edited():
	var item : TreeItem = tree.get_edited()
	var column : int = tree.get_edited_column()
	var resource : Resource = item.get_metadata(0)

	if not resource or column == 0:
		return

	var slotIdx : int = column - 1
	if slotIdx < 0 or slotIdx >= EQUIPMENT_COLUMNS.size():
		return

	var slotValue : int = EQUIPMENT_COLUMNS[slotIdx].value
	var newItemName : String = item.get_text(column).strip_edges()

	var equipmentArray : Array = resource.get("_equipment")
	if not equipmentArray:
		equipmentArray = []
		resource.set("_equipment", equipmentArray)

	if newItemName.is_empty():
		RemoveEquipmentFromSlot(equipmentArray, slotValue)
	else:
		var itemCell : ItemCell = FindItemByName(newItemName)
		if itemCell:
			SetEquipmentInSlot(equipmentArray, slotValue, itemCell)
			item.set_text(column, itemCell.name)
		else:
			item.set_text(column, GetEquippedItemName(equipmentArray, slotValue))

	GameDataUtil.SaveResource(resource)

func FindItemByName(itemName : String) -> ItemCell:
	for itemId in DB.ItemsDB:
		var itemCell : ItemCell = DB.ItemsDB[itemId]
		if itemCell and itemCell.name.to_lower() == itemName.to_lower():
			return itemCell
	return null

func RemoveEquipmentFromSlot(equipmentArray : Array, slot : int):
	if slot < equipmentArray.size():
		equipmentArray[slot] = null

func SetEquipmentInSlot(equipmentArray : Array, slot : int, itemCell : ItemCell):
	while equipmentArray.size() <= slot:
		equipmentArray.push_back(null)

	equipmentArray[slot] = itemCell
