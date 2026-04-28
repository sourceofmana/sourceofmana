extends ColorRect
class_name CellTile

@export var draggable : bool			= false
@export var defaultIcon : CompressedTexture2D = null
@onready var icon : TextureRect			= $Icon
@onready var countLabel : Label			= $Count
@onready var cooldownLabel : Label		= $Cooldown

var cell : BaseCell						= null
var defaultMaterial : Material			= null
var selection : TextureRect				= null
var cooldownTimer : float				= -INF
var shineTimer : float					= -INF
var count : int							= 0
var itemIndex : int						= -1
var hovered : bool						= false
var equipped : bool						= false

const modulateDisable : float			= 0.5

signal selected

# Private
func GetDiffFormat(effect : CellCommons.Modifier, diff : Variant) -> String:
	var diffStr : String = ""
	if float(diff) > 0.0:
		var diffColor : String = "#" + UICommons.ModifierPositiveColor.to_html(false)
		diffStr = " [color=%s](%s %s)[/color]" % [diffColor, CellCommons.FormatModifierValue(effect, diff), "↑"]
	elif float(diff) < 0.0:
		var diffColor : String = "#" + UICommons.ModifierNegativeColor.to_html(false)
		diffStr = " [color=%s](%s %s)[/color]" % [diffColor, CellCommons.FormatModifierValue(effect, diff), "↓"]
	return diffStr

func GetTooltipModifierLine(modifier : StatModifier, currentEquipped : ItemCell, lightColor : String) -> String:
	var modStr : String = "\n%s: [color=%s]%s[/color]" % [CellCommons.GetModifierDisplayName(modifier._effect), lightColor, CellCommons.FormatModifierValue(modifier._effect, modifier._value)]
	if IsInEquipmentSlot() and not CellCommons.IsSameCell(cell, currentEquipped):
		var currentVal : Variant = 0
		if currentEquipped and currentEquipped.modifiers:
			currentVal = currentEquipped.modifiers.Get(modifier._effect, true)
		modStr += GetDiffFormat(modifier._effect, modifier._value - currentVal)
	return modStr

func GetTooltipMissingModifiers(currentEquipped : ItemCell, lightColor : String) -> String:
	if not (currentEquipped and currentEquipped.modifiers and not CellCommons.IsSameCell(cell, currentEquipped)):
		return ""
	var bbcode : String = ""
	for modifier in currentEquipped.modifiers._modifiers:
		if modifier and modifier._persistent:
			if not cell.modifiers or cell.modifiers.Get(modifier._effect, true) == 0:
				bbcode += "\n%s: [color=%s]0[/color]%s" % [CellCommons.GetModifierDisplayName(modifier._effect), lightColor, GetDiffFormat(modifier._effect, -modifier._value)]
	return bbcode

func IsInEquipmentSlot() -> bool:
	return cell is ItemCell and cell.slot >= ActorCommons.Slot.FIRST_EQUIPMENT and cell.slot < ActorCommons.Slot.LAST_EQUIPMENT

func GetCurrentEquipped() -> ItemCell:
	if not (IsInEquipmentSlot() and Launcher.Player and Launcher.Player.inventory):
		return null
	return Launcher.Player.inventory.GetEquipmentCell(cell.slot)

func GetTooltipModifiers(currentEquipped : ItemCell) -> String:
	if not (cell is ItemCell):
		return ""
	var lightColor : String = "#" + UICommons.LightTextColor.to_html(false)
	var bbcode : String = ""
	if cell.modifiers and cell.modifiers.HasAny():
		for modifier in cell.modifiers._modifiers:
			if modifier and (modifier._persistent or cell.usable):
				if bbcode.is_empty():
					bbcode += "\n"
				bbcode += GetTooltipModifierLine(modifier, currentEquipped, lightColor)
	bbcode += GetTooltipMissingModifiers(currentEquipped, lightColor)
	return bbcode

func GetTooltipWeight() -> String:
	if cell.weight == 0:
		return ""
	var lightColor : String = "#" + UICommons.LightTextColor.to_html(false)
	return "\n\nWeight: [color=%s]%dg[/color]" % [lightColor, cell.weight]

func GetTooltipHeader() -> String:
	var bbcode : String = cell.name
	if cell is ItemCell and not cell.customfield.is_empty():
		bbcode += " (%s)" % cell.customfield
	if cell.description:
		bbcode += "\n%s" % cell.description
	if cell is SkillCell and Launcher.Player and Launcher.Player.progress:
		bbcode += "\nLevel: %d" % Launcher.Player.progress.GetSkillLevel(cell)
	return bbcode

func SetToolTip():
	if not cell:
		set_tooltip_text("")
		return
	var currentEquipped : ItemCell = GetCurrentEquipped()
	var bbcode : String = GetTooltipHeader()
	bbcode += GetTooltipModifiers(currentEquipped)
	bbcode += GetTooltipWeight()
	set_tooltip_text(bbcode)

func _make_custom_tooltip(for_text : String) -> Object:
	if for_text.is_empty():
		return null
	var label : RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("default_color", UICommons.TextColor)
	label.text = for_text
	return label

func UpdateCountLabel():
	if countLabel:
		if not defaultIcon and equipped:
			countLabel.text = "~"
		elif count >= 1000:
			countLabel.text = "999+"
		elif count <= 1:
			countLabel.text = ""
		else:
			countLabel.text = str(count)
	if icon:
		var modColor : Color = Color.BLACK if count <= 0 else Color.WHITE
		modColor.a = modulateDisable if count <= 0 else 1.0
		icon.material.set_shader_parameter("modulate", modColor)

# Public
func AssignData(newCell : BaseCell, newCount : int = 1):
	if cell != newCell:
		if cell:
			UnassignData(cell)
		if newCell:
			newCell.used.connect(Used)
	cell = newCell
	count = newCount
	UpdateData()

func UnassignData(sourceCell : BaseCell):
	if icon:
		icon.material.set_shader_parameter("progress", -INF)
		icon.material.set_shader_parameter("modulate", Color.WHITE)
		icon.set_texture(defaultIcon)
	if sourceCell:
		if sourceCell.used.is_connected(Used):
			sourceCell.used.disconnect(Used)

func UpdateData():
	if icon:
		icon.set_texture(cell.icon if cell else defaultIcon)
		if cell and cell is ItemCell and cell.shader != null:
			icon.set_material(cell.shader)
		else:
			icon.set_material(defaultMaterial)

	UpdateCountLabel()
	SetToolTip()
	RefreshColor()
	if not draggable and not defaultIcon:
		set_visible(count > 0 and cell != null)

func AddSelection():
	if not selection:
		selection = UICommons.CellSelectionPreset.instantiate()
		add_child.call_deferred(selection)

func RemoveSelection():
	if selection:
		remove_child.call_deferred(selection)
		selection.queue_free()
		selection = null

static func RefreshShortcuts(baseCell : BaseCell, newCount : int = -1):
	if baseCell == null or not Launcher.Player or not Launcher.Player.inventory:
		return

	if baseCell.type != CellCommons.Type.ITEM:
		newCount = 1
	elif newCount < 0:
		newCount = 0
		for item in Launcher.Player.inventory.items:
			if item and CellCommons.IsSameItem(baseCell, item):
				newCount = item.count
				break

	var tiles : Array[Node] = Launcher.GUI.get_tree().get_nodes_in_group("CellTile")
	for shortcutTile in tiles:
		if shortcutTile and shortcutTile.is_visible() and shortcutTile.draggable and shortcutTile.cell == baseCell:
			shortcutTile.count = newCount
			shortcutTile.equipped = CellCommons.IsEquipped(baseCell)
			shortcutTile.UpdateCountLabel()

func UseCell():
	if cell:
		if cell is ItemCell and not cell.usable and IsInEquipmentSlot():
			if equipped:
				Network.UnequipItem(cell.id, cell.customfield)
			else:
				Network.EquipItem(cell.id, cell.customfield, itemIndex)
		else:
			cell.Use()

func Hover(isHovering : bool):
	hovered = isHovering
	RefreshColor()
	if cell:
		cell.Hover(isHovering)

func Used(cooldown : float = 0.0):
	cooldownTimer = cooldown
	set_process(true)


func ClearCooldown():
	cooldownTimer = -INF
	cooldownLabel.text = ""
	UpdateCountLabel()
	if count > 0:
		shineTimer = 1.0

# Drag
func _get_drag_data(_position : Vector2):
	if cell:
		if cell.usable or IsInEquipmentSlot():
			if icon:
				set_drag_preview(icon.duplicate())
			return cell
	return null

func _can_drop_data(_at_position : Vector2, data):
	if draggable and data is BaseCell and data != cell and data.usable:
		return true
	if defaultIcon and data is ItemCell and data.slot == _get_equipment_slot() and not CellCommons.IsEquipped(data):
		return true
	if not draggable and not defaultIcon and data is ItemCell and CellCommons.IsEquipped(data):
		return true
	return false

func _drop_data(_at_position : Vector2, data):
	if defaultIcon and data is ItemCell and data.slot == _get_equipment_slot():
		var dragItemIndex : int = Launcher.Player.inventory.FindItemIndex(data)
		Network.EquipItem(data.id, data.customfield, dragItemIndex)
	elif not draggable and not defaultIcon and data is ItemCell and CellCommons.IsEquipped(data):
		Network.UnequipItem(data.id, data.customfield)
	elif draggable:
		AssignData(data)
		CellTile.RefreshShortcuts(data)

func _get_equipment_slot() -> ActorCommons.Slot:
	if defaultIcon:
		var slot : ActorCommons.Slot = ActorCommons.GetSlotID(name)
		if slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT:
			return slot
	return ActorCommons.Slot.NONE

# Default
func _ready():
	defaultMaterial = icon.material if icon else null
	UpdateData()
	set_process(false)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				UseCell()
			elif event.pressed:
				selected.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			UnassignData(cell)

func _process(delta : float):
	if cooldownTimer != -INF:
		cooldownTimer -= delta
		if cooldownTimer <= 0.0 or Launcher.Player == null:
			ClearCooldown()
		else:
			if cell.type == CellCommons.Type.SKILL:
				var cooldown : float = SkillCommons.GetCooldown(Launcher.Player, cell)
				var cooldownRatio : float = cooldownTimer / cooldown if cooldown > cooldownTimer else 1.0
				var modColor : Color = Color.GRAY.lerp(Color.BLACK, cooldownRatio)
				modColor.a = modulateDisable + (cooldownRatio * (1.0 - modulateDisable))
				icon.material.set_shader_parameter("modulate", modColor)
				cooldownLabel.text = ("%.1f" if cooldownTimer < 10 else "%.0f") % [cooldownTimer]
	elif shineTimer != -INF:
		shineTimer -= delta
		if shineTimer <= 0.0 or Launcher.Player == null:
			shineTimer = -INF
		icon.material.set_shader_parameter("progress", shineTimer)
	else:
		set_process(false)

func RefreshColor():
	var targetColor : Color
	if hovered:
		targetColor = UICommons.CellTileColorHovered
	elif cell and equipped:
		targetColor = UICommons.CellTileColorEquipped
	else:
		targetColor = UICommons.CellTileColorDefault
	color = Color(targetColor.r, targetColor.g, targetColor.b, color.a)

func _on_focus_entered():
	Hover(true)

func _on_focus_exited():
	Hover(false)

func _on_mouse_entered():
	Hover(true)

func _on_mouse_exited():
	Hover(false)
