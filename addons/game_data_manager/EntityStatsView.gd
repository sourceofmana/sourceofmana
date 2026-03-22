@tool
extends TableViewBase

#
const STAT_COLUMNS : Array[Dictionary] = [
	{ "name" : "level", "type" : TYPE_INT },
	{ "name" : "race", "type" : TYPE_STRING },
	{ "name" : "gender", "type" : TYPE_STRING },
	{ "name" : "hairstyle", "type" : TYPE_STRING },
	{ "name" : "haircolor", "type" : TYPE_STRING },
	{ "name" : "skintone", "type" : TYPE_STRING },
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
	tree.columns = 1 + STAT_COLUMNS.size()
	tree.hide_root = true
	tree.column_titles_visible = true
	tree.select_mode = Tree.SELECT_SINGLE

	tree.set_column_title(0, "Entity")
	tree.set_column_expand(0, true)
	tree.set_column_custom_minimum_width(0, 120)
	tree.set_column_expand_ratio(0, 1.0)

	for i in STAT_COLUMNS.size():
		var columnIdx : int = i + 1
		tree.set_column_title(columnIdx, STAT_COLUMNS[i].name)
		tree.set_column_expand(columnIdx, true)
		tree.set_column_custom_minimum_width(columnIdx, 90)
		tree.set_column_expand_ratio(columnIdx, 1.0)

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

	for i in STAT_COLUMNS.size():
		var columnIdx : int = i + 1
		var statStr : String = STAT_COLUMNS[i].name

		var hasValue : bool = stats and stats.has(statStr)
		var statValue : String = GetStatValue(stats, statStr)
		var parentValue : String = GetStatValue(parentStats, statStr) if parentStats else ""

		var displayValue : String = ""
		var isInherited : bool = false

		if hasValue and statValue != "":
			displayValue = str(statValue)
			isInherited = (parent and statValue == parentValue)
		elif parentValue != "":
			displayValue = str(parentValue)
			isInherited = true
		else:
			displayValue = ""

		if isInherited and displayValue != "":
			item.set_custom_color(columnIdx, Color.LIGHT_SLATE_GRAY)
		else:
			item.clear_custom_color(columnIdx)

		item.set_text(columnIdx, displayValue)
		item.set_editable(columnIdx, true)

func GetStatValue(stats : Variant, statStr : String) -> String:
	if not stats or not stats.has(statStr):
		return ""

	var value : Variant = stats[statStr]
	if value is int:
		match statStr:
			"race":
				var race : RaceData = DB.RacesDB.get(value)
				return race._name if race else str(value)
			"hairstyle":
				var hairstyle : HairstyleData = DB.HairstylesDB.get(value)
				return hairstyle._name if hairstyle else str(value)
			"haircolor":
				var palette : FileData = DB.PalettesDB[DB.Palette.HAIR].get(value)
				return palette._name if palette else str(value)
			"skintone":
				var palette : FileData = DB.PalettesDB[DB.Palette.SKIN].get(value)
				return palette._name if palette else str(value)
			"gender":
				return ActorCommons.GetGenderName(value)
			_:
				return str(value)

	return str(value)

#
func _on_item_edited():
	var item : TreeItem = tree.get_edited()
	var column : int = tree.get_edited_column()
	var resource : Resource = item.get_metadata(0)

	if not resource or column == 0:
		return

	var statIdx : int = column - 1
	if statIdx < 0 or statIdx >= STAT_COLUMNS.size():
		return

	var statStr : String = STAT_COLUMNS[statIdx].name
	var statType : int = STAT_COLUMNS[statIdx].type
	var newValueStr : String = item.get_text(column).strip_edges()

	var stats : Variant = resource.get("_stats")
	if not stats:
		stats = {}
		resource.set("_stats", stats)

	var newValue : Variant
	if statType == TYPE_INT:
		newValue = newValueStr.to_int() if not newValueStr.is_empty() else 0
	else:
		newValue = newValueStr

	if statType == TYPE_STRING and newValueStr.is_empty():
		if stats.has(statStr):
			stats.erase(statStr)
	else:
		stats[statStr] = newValue

	var displayText : String = ""
	if statType == TYPE_INT:
		displayText = str(newValue) if newValue != 0 else ""
	else:
		displayText = str(newValue) if newValue != "" else ""
	item.set_text(column, displayText)

	GameDataUtil.SaveResource(resource)
