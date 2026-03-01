@tool
extends TableViewBase

#
const BASE_STAT_COLUMNS : Array[Dictionary] = [
	{ "name" : "walkSpeed", "type" : TYPE_FLOAT },
	{ "name" : "attack", "type" : TYPE_INT },
	{ "name" : "defense", "type" : TYPE_INT },
	{ "name" : "mattack", "type" : TYPE_INT },
	{ "name" : "mdefense", "type" : TYPE_INT },
	{ "name" : "attackRange", "type" : TYPE_INT },
	{ "name" : "critRate", "type" : TYPE_FLOAT },
	{ "name" : "dodgeRate", "type" : TYPE_FLOAT },
	{ "name" : "castAttackDelay", "type" : TYPE_FLOAT },
	{ "name" : "cooldownAttackDelay", "type" : TYPE_FLOAT },
	{ "name" : "maxHealth", "type" : TYPE_INT },
	{ "name" : "maxStamina", "type" : TYPE_INT },
	{ "name" : "maxMana", "type" : TYPE_INT },
	{ "name" : "regenHealth", "type" : TYPE_FLOAT },
	{ "name" : "regenStamina", "type" : TYPE_FLOAT },
	{ "name" : "regenMana", "type" : TYPE_FLOAT },
]

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
	tree.clear()
	tree.columns = 1 + BASE_STAT_COLUMNS.size()
	tree.hide_root = true
	tree.column_titles_visible = true
	tree.select_mode = Tree.SELECT_SINGLE

	tree.set_column_title(0, "Entity")
	tree.set_column_expand(0, true)
	tree.set_column_custom_minimum_width(0, 120)
	tree.set_column_expand_ratio(0, 1.5)

	for i in BASE_STAT_COLUMNS.size():
		var columnIdx : int = i + 1
		tree.set_column_title(columnIdx, BASE_STAT_COLUMNS[i].name)
		tree.set_column_expand(columnIdx, true)
		tree.set_column_custom_minimum_width(columnIdx, 90)
		tree.set_column_expand_ratio(columnIdx, 0.8)

func UpdateTreeItem(item : TreeItem, resource : Resource):
	item.set_text(0, resource._name if resource.get("_name") else "Unnamed")
	item.set_editable(0, false)
	item.set_metadata(0, resource)

	var stats : Variant = resource.get("_stats")
	var parent : Variant = resource.get("_parent")
	var parentStats : Variant = null
	if parent:
		var mergedParent : Variant = parent.GetMergedEntity()
		parentStats = mergedParent.get("_stats") if mergedParent else null

	var defaultBaseStats : BaseStats = BaseStats.new()

	for i in BASE_STAT_COLUMNS.size():
		var colIdx : int = i + 1
		var statStr : String = BASE_STAT_COLUMNS[i].name
		var statType : int = BASE_STAT_COLUMNS[i].type

		var hasValue : bool = stats and stats.has(statStr)
		var currentValue : Variant = GetStatValue(stats, statStr, statType)
		var parentValue : Variant = GetStatValue(parentStats, statStr, statType) if parentStats else (0 if statType == TYPE_INT else 0.0)
		var defaultValue : Variant = defaultBaseStats.get(statStr) if statStr in defaultBaseStats else (0 if statType == TYPE_INT else 0.0)

		var displayValue : Variant
		var isInherited : bool = false
		var isDefault : bool = false

		if hasValue and currentValue != 0:
			displayValue = currentValue
			isInherited = (parent != null and currentValue == parentValue)
		elif parent != null and parentValue != 0:
			displayValue = parentValue
			isInherited = true
		elif defaultValue != 0:
			displayValue = defaultValue
			isDefault = true
		else:
			displayValue = 0 if statType == TYPE_INT else 0.0

		if isInherited or isDefault:
			item.set_custom_color(colIdx, Color.LIGHT_SLATE_GRAY)
		else:
			item.set_custom_color(colIdx, Color.WHITE)

		if statType == TYPE_FLOAT:
			item.set_text(colIdx, "%.2f" % displayValue if displayValue != 0 else "")
		else:
			item.set_text(colIdx, str(displayValue) if displayValue != 0 else "")
		item.set_editable(colIdx, true)

func GetStatValue(stats : Variant, statName : String, statType : int) -> Variant:
	if not stats or not stats.has(statName):
		return 0 if statType == TYPE_INT else 0.0
	return stats[statName]

#
func _on_item_edited():
	var item : TreeItem = tree.get_edited()
	var column : int = tree.get_edited_column()
	var resource : Resource = item.get_metadata(0)

	if not resource or column == 0:
		return

	var statIdx : int = column - 1
	if statIdx < 0 or statIdx >= BASE_STAT_COLUMNS.size():
		return

	var statName : String = BASE_STAT_COLUMNS[statIdx].name
	var statType : int = BASE_STAT_COLUMNS[statIdx].type
	var valueStr : String = item.get_text(column).strip_edges()

	var value : Variant
	if statType == TYPE_FLOAT:
		value = valueStr.to_float() if not valueStr.is_empty() else 0.0
	else:
		value = valueStr.to_int() if not valueStr.is_empty() else 0

	var stats : Dictionary = resource.get("_stats")
	if not stats:
		stats = {}
		resource.set("_stats", stats)

	stats[statName] = value

	if statType == TYPE_FLOAT:
		item.set_text(column, "%.2f" % value if value != 0 else "")
	else:
		item.set_text(column, str(value) if value != 0 else "")

	GameDataUtil.SaveResource(resource)
