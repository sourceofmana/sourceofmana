@tool
extends Control

#
const ATTRIBUTES : PackedStringArray = ["strength", "vitality", "agility", "endurance", "concentration"]
const ATTR_LABELS : PackedStringArray = ["STR", "VIT", "AGI", "END", "CON"]
const MATRIX_COLS : int = 19
const COL_TITLES : PackedStringArray = ["Entity", "Lvl", "XP", "Atk", "Def", "MAtk", "MDef", "P→E Phy", "P→E Mag", "E→P Phy", "E→P Mag", "Ratio", "MRatio", "P Hits", "P TTK", "E Hits", "E TTK", "KTL(P)", "KTL(E)"]
const COL_WIDTHS : PackedInt32Array = [130, 60, 60, 50, 50, 55, 55, 75, 80, 75, 80, 65, 70, 55, 60, 55, 60, 65, 65]
const COL_SORT_KEYS : PackedStringArray = ["name", "level", "xp", "atk", "def", "matk", "mdef", "p_phys", "p_mag", "e_phys", "e_mag", "ratio", "mratio", "p_hits", "p_ttk", "e_hits", "e_ttk", "kills_p", "kills_e"]

#
const PlayerHitsBandMin : int = 3
const PlayerHitsBandMax : int = 8
const EnemyHitsBandMin : int = 8
const EnemyHitsBandMax : int = 40

#
var itemsBySlot : Dictionary[int, Array] = {}
var itemsByHash : Dictionary[int, ItemCell] = {}
var entities : Array[EntityData] = []

var iconPreviewCache : Dictionary = {}

var levelSpin : SpinBox = null
var pointsLabel : Label = null
var attributeSpins : Dictionary[String, SpinBox] = {}
var equipDropdowns : Dictionary[int, OptionButton] = {}
var modifiersContainer : VBoxContainer = null
var matrixTree : Tree = null
var entityLevels : Dictionary[int, int] = {}
var originalResources : Dictionary[int, EntityData] = {}
var sortColumn : int = 0
var sortAscending : bool = true

#
func _ready():
	if not GameDataUtil.is_part_of_edited_scene(self):
		LoadResources()
		await GenerateIconPreviews()
		BuildUI()

func LoadResources():
	itemsBySlot.clear()
	itemsByHash.clear()
	entities.clear()
	iconPreviewCache.clear()
	originalResources.clear()

	if DirAccess.dir_exists_absolute(Path.ItemPst):
		for resourcePath in FileSystem.ParseResources(Path.ItemPst):
			var cell : Resource = FileSystem.LoadResource(resourcePath, false)
			if cell is ItemCell and cell.name and cell.id > 0:
				var item : ItemCell = cell
				itemsByHash[item.id] = item
				var slot : int = item.slot
				if slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT:
					if slot not in itemsBySlot:
						itemsBySlot[slot] = []
					itemsBySlot[slot].append(item)

	for slot : int in itemsBySlot:
		itemsBySlot[slot].sort_custom(SortItemsByName)

	if DirAccess.dir_exists_absolute(Path.EntityPst):
		for resourcePath in FileSystem.ParseResources(Path.EntityPst):
			var res : Resource = FileSystem.LoadResource(resourcePath, false)
			if res is EntityData:
				var entity : EntityData = res.GetMergedEntity()
				if entity._name != "":
					entities.push_back(entity)
					originalResources[entity._id] = res

	entities.sort_custom(SortEntitiesByName)

func GenerateIconPreviews():
	for item : ItemCell in itemsByHash.values():
		if item.icon and item.shader and item.shader is Material:
			await CreateMaterialPreview(item.icon, item.shader, item.resource_path)

func CreateMaterialPreview(texture : Texture2D, material : Material, cacheKey : String) -> ImageTexture:
	if not Engine.is_editor_hint() or not texture or not material:
		return null
	if iconPreviewCache.has(cacheKey):
		return iconPreviewCache[cacheKey]
	var textureSize : Vector2 = texture.get_size()
	if textureSize.x == 0 or textureSize.y == 0:
		return null
	var viewport := SubViewport.new()
	viewport.size = textureSize
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.material = material
	sprite.centered = false
	add_child(viewport)
	viewport.add_child(sprite)
	await get_tree().process_frame
	await get_tree().process_frame
	var image : Image = viewport.get_texture().get_image()
	viewport.queue_free()
	if image:
		var result : ImageTexture = ImageTexture.create_from_image(image)
		iconPreviewCache[cacheKey] = result
		return result
	return null

#
func BuildUI():
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var topbar := HBoxContainer.new()
	vbox.add_child(topbar)

	var refreshBtn := Button.new()
	refreshBtn.text = "Refresh"
	refreshBtn.pressed.connect(_on_refresh_pressed)
	topbar.add_child(refreshBtn)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	BuildPlayerPanel(split)
	BuildMatrixPanel(split)

	UpdateAttributeUI()
	RefreshMatrix()

func BuildPlayerPanel(parent : Node):
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 275
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)

	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(container)

	var hdr := Label.new()
	hdr.text = "── Player ──"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(hdr)

	var levelRow := HBoxContainer.new()
	container.add_child(levelRow)
	var lvlLbl := Label.new()
	lvlLbl.text = "Level:"
	lvlLbl.custom_minimum_size.x = 85
	levelRow.add_child(lvlLbl)
	levelSpin = SpinBox.new()
	levelSpin.min_value = 1
	levelSpin.max_value = 135
	levelSpin.value = 1
	levelSpin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levelSpin.value_changed.connect(_on_level_changed)
	levelRow.add_child(levelSpin)

	pointsLabel = Label.new()
	pointsLabel.text = "Points: 0 / 13  (free: 13)"
	container.add_child(pointsLabel)

	for i : int in ATTRIBUTES.size():
		var row := HBoxContainer.new()
		container.add_child(row)
		var lbl := Label.new()
		lbl.text = ATTR_LABELS[i] + ":"
		lbl.custom_minimum_size.x = 85
		row.add_child(lbl)
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = 20
		spin.value = 0
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(_on_attribute_changed)
		attributeSpins[ATTRIBUTES[i]] = spin
		row.add_child(spin)

	container.add_child(HSeparator.new())

	var equipHdr := Label.new()
	equipHdr.text = "── Equipment ──"
	equipHdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(equipHdr)

	for slotIdx : int in range(ActorCommons.Slot.FIRST_EQUIPMENT, ActorCommons.Slot.LAST_EQUIPMENT):
		var row := HBoxContainer.new()
		container.add_child(row)
		var lbl := Label.new()
		lbl.text = ActorCommons.GetSlotName(slotIdx) + ":"
		lbl.custom_minimum_size.x = 65
		row.add_child(lbl)
		var opt := OptionButton.new()
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt.add_item("(none)")
		for item : ItemCell in itemsBySlot.get(slotIdx, []):
			var icon : Texture2D = iconPreviewCache.get(item.resource_path, item.icon)
			if icon:
				opt.add_icon_item(icon, item.name)
			else:
				opt.add_item(item.name)
			opt.set_item_metadata(opt.item_count - 1, item.id)
		opt.item_selected.connect(_on_equip_changed)
		equipDropdowns[slotIdx] = opt
		row.add_child(opt)

	container.add_child(HSeparator.new())

	var modHdr := Label.new()
	modHdr.text = "── Active Modifiers ──"
	modHdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(modHdr)

	modifiersContainer = VBoxContainer.new()
	container.add_child(modifiersContainer)

	var noModLbl := Label.new()
	noModLbl.text = "(no modifiers)"
	modifiersContainer.add_child(noModLbl)

func BuildMatrixPanel(parent : Node):
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)

	var titleLbl := Label.new()
	titleLbl.text = "Combat Matrix"
	titleLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titleLbl)

	matrixTree = Tree.new()
	matrixTree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	matrixTree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	matrixTree.hide_root = true
	matrixTree.columns = MATRIX_COLS
	matrixTree.column_titles_visible = true
	matrixTree.item_edited.connect(_on_matrix_item_edited)
	matrixTree.column_title_clicked.connect(_on_column_title_clicked)
	vbox.add_child(matrixTree)

	for i : int in MATRIX_COLS:
		matrixTree.set_column_custom_minimum_width(i, COL_WIDTHS[i])
		matrixTree.set_column_expand(i, i == 0)
	UpdateColumnTitles()

func UpdateColumnTitles():
	if not matrixTree:
		return
	for i : int in MATRIX_COLS:
		var title : String = COL_TITLES[i]
		if i == sortColumn:
			title += "  " + ("▲" if sortAscending else "▼")
		matrixTree.set_column_title(i, title)

#
func GetSelectedItem(opt : OptionButton) -> ItemCell:
	var itemHash : Variant = opt.get_item_metadata(opt.selected)
	if itemHash != null and itemsByHash.has(itemHash):
		return itemsByHash[itemHash]
	return null

func BuildStatForPlayer() -> ActorStats:
	var stat := ActorStats.new()
	stat.level = int(levelSpin.value)
	stat.strength = int((attributeSpins["strength"]).value)
	stat.vitality = int((attributeSpins["vitality"]).value)
	stat.agility = int((attributeSpins["agility"]).value)
	stat.endurance = int((attributeSpins["endurance"]).value)
	stat.concentration = int((attributeSpins["concentration"]).value)

	for slotIdx : int in equipDropdowns:
		var item : ItemCell = GetSelectedItem(equipDropdowns[slotIdx])
		if item and item.modifiers:
			for modifier : StatModifier in item.modifiers._modifiers:
				if modifier and modifier._persistent:
					stat.modifiers.Add(modifier)

	stat.RefreshEntityStats()
	return stat

func BuildStatForEntity(entityData : EntityData, customLevel : int) -> ActorStats:
	var stat := ActorStats.new()
	var stats : Dictionary = entityData._stats

	stat.strength = int(stats.get("strength", 0))
	stat.vitality = int(stats.get("vitality", 0))
	stat.agility = int(stats.get("agility", 0))
	stat.endurance = int(stats.get("endurance", 0))
	stat.concentration = int(stats.get("concentration", 0))
	stat.level = customLevel

	stat.morphStat.attack = int(stats.get("attack", stat.morphStat.attack))
	stat.morphStat.defense = int(stats.get("defense", stat.morphStat.defense))
	stat.morphStat.mattack = int(stats.get("mattack", stat.morphStat.mattack))
	stat.morphStat.mdefense = int(stats.get("mdefense", stat.morphStat.mdefense))
	stat.morphStat.maxHealth = int(stats.get("maxHealth", stat.morphStat.maxHealth))
	stat.morphStat.critRate = float(stats.get("critRate", stat.morphStat.critRate))
	stat.morphStat.dodgeRate = float(stats.get("dodgeRate", stat.morphStat.dodgeRate))
	stat.morphStat.attackRange = int(stats.get("attackRange", stat.morphStat.attackRange))

	for item : ItemCell in entityData._equipment:
		if item and item.modifiers:
			for modifier : StatModifier in item.modifiers._modifiers:
				if modifier and modifier._persistent:
					stat.modifiers.Add(modifier)

	stat.RefreshEntityStats()
	return stat

func UpdateAttributeUI():
	var maxPts : int = Formula.GetMaxAttributePoints(int(levelSpin.value))
	var used : int = 0
	for att : String in ATTRIBUTES:
		used += int(attributeSpins[att].value)

	var remaining : int = maxPts - used
	pointsLabel.text = "Points: %d / %d  (free: %d)" % [used, maxPts, remaining]

	for att : String in ATTRIBUTES:
		var spin : SpinBox = attributeSpins[att]
		spin.max_value = min(ActorCommons.MaxPointPerAttributes, int(spin.value) + remaining)

func TrimAttributesToBudget():
	var maxPts : int = Formula.GetMaxAttributePoints(int(levelSpin.value))
	var used : int = 0
	for att : String in ATTRIBUTES:
		used += int((attributeSpins[att]).value)
	if used <= maxPts:
		return

	var reversed : Array[String] = []
	for att : String in ATTRIBUTES:
		reversed.push_front(att)

	for att : String in reversed:
		if used <= maxPts:
			break
		var spin : SpinBox = attributeSpins[att]
		var excess : int = used - maxPts
		var cut : int = min(int(spin.value), excess)
		spin.set_value_no_signal(int(spin.value) - cut)
		used -= cut

func RefreshModifiers():
	for child : Node in modifiersContainer.get_children():
		child.queue_free()

	var aggregated : Dictionary = {}

	for slotIdx : int in equipDropdowns:
		var item : ItemCell = GetSelectedItem(equipDropdowns[slotIdx])
		if item and item.modifiers:
			for modifier : StatModifier in item.modifiers._modifiers:
				if modifier and modifier._persistent:
					var eff : CellCommons.Modifier = modifier._effect
					aggregated[eff] = float(aggregated.get(eff, 0.0)) + float(modifier._value)

	if aggregated.is_empty():
		var lbl := Label.new()
		lbl.text = "(no modifiers)"
		modifiersContainer.add_child(lbl)
		return

	for eff in aggregated:
		var val : float = float(aggregated[eff])
		var signStr : String = "+" if val >= 0.0 else ""
		var display : String = CellCommons.GetModifierDisplayName(eff)
		var lbl := Label.new()
		lbl.text = display + ": " + signStr + ("%.2f" % val if val != floori(val) else str(int(val)))
		modifiersContainer.add_child(lbl)

func RefreshMatrix():
	if not matrixTree:
		return

	matrixTree.clear()
	var root : TreeItem = matrixTree.create_item()

	var ps : ActorStats = BuildStatForPlayer()

	var playerRow : TreeItem = matrixTree.create_item(root)
	var playerColor : Color = Color(0.7, 0.9, 1.0)
	for c : int in MATRIX_COLS:
		playerRow.set_custom_color(c, playerColor)
	playerRow.set_text(0, "PLAYER")
	playerRow.set_text(1, str(ps.level))
	playerRow.set_text(2, "—")
	playerRow.set_text(3, str(ps.current.attack))
	playerRow.set_text(4, str(ps.current.defense))
	playerRow.set_text(5, str(ps.current.mattack))
	playerRow.set_text(6, str(ps.current.mdefense))
	for c : int in range(7, MATRIX_COLS):
		playerRow.set_text(c, "—")

	var rows : Array[Dictionary] = []
	for entityData : EntityData in entities:
		if entityData._stats.get("level", 0) <= 0:
			continue

		var entityLevel : int = entityLevels.get(entityData._id, int(entityData._stats.get("level", 1)))
		var es : ActorStats = BuildStatForEntity(entityData, entityLevel)
		var pPhys : int = max(1, ps.current.attack - es.current.defense)
		var pMag : int = max(1, ps.current.mattack - es.current.mdefense)
		var ePhys : int = max(1, es.current.attack - ps.current.defense)
		var eMag : int = max(1, es.current.mattack - ps.current.mdefense)
		var pHits : int = ceili(float(es.current.maxHealth) / float(pPhys))
		var eHits : int = ceili(float(ps.current.maxHealth) / float(ePhys))
		var pTTK : float = pHits * (ps.current.castAttackDelay + ps.current.cooldownAttackDelay)
		var eTTK : float = eHits * (es.current.castAttackDelay + es.current.cooldownAttackDelay)
		var xp : int = entityData._stats.get("baseExp", 1)
		var neededXpPlayer : int = Experience.GetNeededExperienceForNextLevel(ps.level)
		var neededXpEntity : int = Experience.GetNeededExperienceForNextLevel(entityLevel)
		var killsP : int = ceili(float(neededXpPlayer) / float(xp)) if neededXpPlayer != Experience.MAX_LEVEL_REACHED and xp > 0 else -1
		var killsE : int = ceili(float(neededXpEntity) / float(xp)) if neededXpEntity != Experience.MAX_LEVEL_REACHED and xp > 0 else -1

		rows.append({
			"entity": entityData,
			"name": entityData._name,
			"level": entityLevel,
			"atk": es.current.attack,
			"def": es.current.defense,
			"matk": es.current.mattack,
			"mdef": es.current.mdefense,
			"p_phys": pPhys,
			"p_mag": pMag,
			"e_phys": ePhys,
			"e_mag": eMag,
			"ratio": float(pPhys) / max(1.0, float(ePhys)),
			"mratio": float(pMag) / max(1.0, float(eMag)),
			"p_hits": pHits,
			"p_ttk": pTTK,
			"e_hits": eHits,
			"e_ttk": eTTK,
			"xp": xp,
			"kills_p": killsP,
			"kills_e": killsE,
		})

	rows.sort_custom(SortRows)

	var green : Color = Color(0.4, 0.9, 0.4)
	var red : Color = Color(0.9, 0.5, 0.5)

	for row : Dictionary in rows:
		var entityData : EntityData = row["entity"]
		var entityLevel : int = int(row["level"])
		var pPhys : int = int(row["p_phys"])
		var pMag : int = int(row["p_mag"])
		var ePhys : int = int(row["e_phys"])
		var eMag : int = int(row["e_mag"])
		var ratio : float = float(row["ratio"])
		var mratio : float = float(row["mratio"])

		var treeItem : TreeItem = matrixTree.create_item(root)
		treeItem.set_metadata(0, entityData)
		treeItem.set_text(0, entityData._name)
		treeItem.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
		treeItem.set_range_config(1, 1.0, 135.0, 1.0)
		treeItem.set_range(1, float(entityLevel))
		treeItem.set_editable(1, true)
		treeItem.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
		treeItem.set_range_config(2, 0.0, 999999.0, 1.0)
		treeItem.set_range(2, float(int(row["xp"])))
		treeItem.set_editable(2, true)
		treeItem.set_text(3, str(int(row["atk"])))
		treeItem.set_text(4, str(int(row["def"])))
		treeItem.set_text(5, str(int(row["matk"])))
		treeItem.set_text(6, str(int(row["mdef"])))
		treeItem.set_text(7, str(pPhys))
		treeItem.set_text(8, str(pMag))
		treeItem.set_text(9, str(ePhys))
		treeItem.set_text(10, str(eMag))
		treeItem.set_text(11, "%.2f×" % ratio)
		treeItem.set_text(12, "%.2f×" % mratio)

		var pHits : int = int(row["p_hits"])
		var eHits : int = int(row["e_hits"])
		var killsP : int = int(row["kills_p"])
		var killsE : int = int(row["kills_e"])
		treeItem.set_text(13, str(pHits))
		treeItem.set_text(14, "%.1fs" % float(row["p_ttk"]))
		treeItem.set_text(15, str(eHits))
		treeItem.set_text(16, "%.1fs" % float(row["e_ttk"]))
		treeItem.set_text(17, str(killsP) if killsP > 0 else "—")
		treeItem.set_text(18, str(killsE) if killsE > 0 else "—")

		treeItem.set_custom_color(13, green if pHits >= PlayerHitsBandMin and pHits <= PlayerHitsBandMax else red)
		treeItem.set_custom_color(15, green if eHits >= EnemyHitsBandMin and eHits <= EnemyHitsBandMax else red)

		if pPhys > ePhys:
			treeItem.set_custom_color(7, green)
			treeItem.set_custom_color(9, red)
		elif pPhys < ePhys:
			treeItem.set_custom_color(7, red)
			treeItem.set_custom_color(9, green)

		if pMag > eMag:
			treeItem.set_custom_color(8, green)
			treeItem.set_custom_color(10, red)
		elif pMag < eMag:
			treeItem.set_custom_color(8, red)
			treeItem.set_custom_color(10, green)

		treeItem.set_custom_color(11, green if ratio > 1.0 else (red if ratio < 1.0 else Color.WHITE))
		treeItem.set_custom_color(12, green if mratio > 1.0 else (red if mratio < 1.0 else Color.WHITE))

func SortItemsByName(a : ItemCell, b : ItemCell) -> bool:
	return a.name < b.name

func SortEntitiesByName(a : EntityData, b : EntityData) -> bool:
	return a._name < b._name

func SortRows(a : Dictionary, b : Dictionary) -> bool:
	var key : String = COL_SORT_KEYS[sortColumn]
	match sortColumn:
		0:
			var va : String = String(a[key])
			var vb : String = String(b[key])
			if va == vb: return false
			return (va < vb) if sortAscending else (va > vb)
		11, 12, 14, 16:
			var va : float = float(a[key])
			var vb : float = float(b[key])
			if va == vb: return false
			return (va < vb) if sortAscending else (va > vb)
		_:
			var va : int = int(a[key])
			var vb : int = int(b[key])
			if va == vb: return false
			return (va < vb) if sortAscending else (va > vb)

#
func _on_level_changed(_val : float):
	TrimAttributesToBudget()
	UpdateAttributeUI()
	RefreshMatrix()

func _on_attribute_changed(_val : float):
	UpdateAttributeUI()
	RefreshMatrix()

func _on_equip_changed(_idx : int):
	RefreshModifiers()
	RefreshMatrix()

func _on_column_title_clicked(column : int, _button : int):
	if sortColumn == column:
		sortAscending = not sortAscending
	else:
		sortColumn = column
		sortAscending = true

	UpdateColumnTitles()
	RefreshMatrix()

func _on_matrix_item_edited():
	var item : TreeItem = matrixTree.get_edited()
	var column : int = matrixTree.get_edited_column()
	if not item or (column != 1 and column != 2):
		return

	var entityData : EntityData = item.get_metadata(0)
	if not entityData:
		return

	if column == 1:
		var newLevel : int = int(item.get_range(1))
		entityLevels[entityData._id] = newLevel
		SaveEntityStat(entityData, "level", newLevel)
	elif column == 2:
		SaveEntityStat(entityData, "baseExp", int(item.get_range(2)))

	RefreshMatrix()

func SaveEntityStat(entityData : EntityData, statName : String, value : int):
	var original : EntityData = originalResources.get(entityData._id)
	if not original:
		return
	var stats : Variant = original.get("_stats")
	if not stats:
		stats = {}
		original.set("_stats", stats)
	stats[statName] = value
	entityData._stats[statName] = value
	GameDataUtil.SaveResource(original)

func _on_refresh_pressed():
	for child : Node in get_children():
		child.queue_free()

	levelSpin = null
	pointsLabel = null
	attributeSpins.clear()
	equipDropdowns.clear()
	modifiersContainer = null
	matrixTree = null
	entityLevels.clear()

	LoadResources()
	await GenerateIconPreviews()
	BuildUI()
