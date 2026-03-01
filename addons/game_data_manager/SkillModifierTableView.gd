@tool
extends TableViewBase

var MODIFIER_COLUMNS : Array[Dictionary] = []

#
func GetResourcePath() -> String:
	return Path.SkillPst

func IsValidResource(resource : Resource) -> bool:
	return resource is SkillCell

func GetResourceName(resource : Resource) -> String:
	return str(resource.get("name")) if resource.get("name") else ""

func GetCountText(filtered : int, total : int) -> String:
	return "%d / %d skills" % [filtered, total]

func Setup():
	SetupModifierColumns()

	tree.clear()
	tree.columns = 1 + MODIFIER_COLUMNS.size()
	tree.hide_root = true
	tree.column_titles_visible = true
	tree.select_mode = Tree.SELECT_SINGLE

	tree.set_column_title(0, "Skill")
	tree.set_column_expand(0, true)
	tree.set_column_custom_minimum_width(0, 150)
	tree.set_column_expand_ratio(0, 1.5)

	for i in MODIFIER_COLUMNS.size():
		var columnIdx : int = i + 1
		tree.set_column_title(columnIdx, MODIFIER_COLUMNS[i].name)
		tree.set_column_expand(columnIdx, true)
		tree.set_column_custom_minimum_width(columnIdx, 80)
		tree.set_column_expand_ratio(columnIdx, 0.8)

func SetupModifierColumns():
	MODIFIER_COLUMNS.clear()
	for key in CellCommons.Modifier.keys():
		var value : int = CellCommons.Modifier[key]
		if key != "None" and key != "Count":
			MODIFIER_COLUMNS.push_back({ "name" : key, "value" : value })

func UpdateTreeItem(item : TreeItem, resource : Resource):
	item.set_text(0, resource.name if resource.get("name") else "Unnamed")
	item.set_editable(0, false)
	item.set_metadata(0, resource)

	var cellModifier : CellModifier = resource.get("modifiers")

	for i in MODIFIER_COLUMNS.size():
		var columnIdx : int = i + 1
		var modifierType : int = MODIFIER_COLUMNS[i].value

		var modifierValue : int = GetModifierValue(cellModifier, modifierType)

		item.set_text(columnIdx, str(modifierValue) if modifierValue != 0 else "")
		item.set_editable(columnIdx, true)

func GetModifierValue(cellModifier : CellModifier, modifierType : int) -> int:
	if not cellModifier or not cellModifier._modifiers:
		return 0

	for modifier in cellModifier._modifiers:
		if modifier and modifier._effect == modifierType:
			return modifier._value

	return 0

#
func _on_item_edited():
	var item : TreeItem = tree.get_edited()
	var column : int = tree.get_edited_column()
	var resource : Resource = item.get_metadata(0)

	if not resource or column == 0:
		return

	var modifierIdx : int = column - 1
	if modifierIdx < 0 or modifierIdx >= MODIFIER_COLUMNS.size():
		return

	var modifierType : int = MODIFIER_COLUMNS[modifierIdx].value
	var newValueStr : String = item.get_text(column).strip_edges()
	var newValue : int = newValueStr.to_int() if not newValueStr.is_empty() else 0

	var cellModifier : CellModifier = resource.get("modifiers")
	if not cellModifier:
		cellModifier = CellModifier.new()
		resource.set("modifiers", cellModifier)

	if not cellModifier._modifiers:
		cellModifier._modifiers = []

	var found : bool = false
	for i in range(cellModifier._modifiers.size() - 1, -1, -1):
		var modifier : StatModifier = cellModifier._modifiers[i]
		if modifier and modifier._effect == modifierType:
			if newValue == 0:
				cellModifier._modifiers.remove_at(i)
				found = true
			else:
				modifier._value = newValue
				found = true
			break

	if not found and newValue != 0:
		var newModifier : StatModifier = StatModifier.new()
		newModifier._effect = modifierType
		newModifier._value = newValue
		newModifier._persistent = false
		cellModifier._modifiers.push_back(newModifier)

	item.set_text(column, str(newValue) if newValue != 0 else "")

	GameDataUtil.SaveResource(resource)
