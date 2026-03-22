extends WindowPanel

@onready var grid : GridContainer		= $Margin/HBoxContainer/ItemsBox/Margin/Container/Grid

@onready var itemButtons : Control		= $Margin/HBoxContainer/ItemsBox/ItemButtons
@onready var dropButtons : Control		= $Margin/HBoxContainer/ItemsBox/DropButtons

@onready var dropButton : Button		= $Margin/HBoxContainer/ItemsBox/ItemButtons/Drop
@onready var useButton : Button			= $Margin/HBoxContainer/ItemsBox/ItemButtons/Use
@onready var equipButton : Button		= $Margin/HBoxContainer/ItemsBox/ItemButtons/Equip
@onready var unequipButton : Button		= $Margin/HBoxContainer/ItemsBox/ItemButtons/Unequip

@onready var lessDropButton : Button	= $Margin/HBoxContainer/ItemsBox/DropButtons/Less
@onready var moreDropButton : Button	= $Margin/HBoxContainer/ItemsBox/DropButtons/More
@onready var dropLabel : Label			= $Margin/HBoxContainer/ItemsBox/DropButtons/Label

@onready var equipmentSlots : Array[CellTile] = [
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Chest,
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Legs,
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Feet,
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Hands,
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Head,
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Neck,
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Weapon,
	$Margin/HBoxContainer/InfoScroll/InfoBox/EquipmentGrid/Shield,
]

@onready var modifiersText : RichTextLabel	= $Margin/HBoxContainer/InfoScroll/InfoBox/ModifiersText
@onready var weightBar : Control			= $Margin/HBoxContainer/InfoScroll/InfoBox/WeightBox/WeightBar
@onready var slotsBar : Control				= $Margin/HBoxContainer/InfoScroll/InfoBox/SlotsBox/SlotsBar

enum ButtonMode
{
	UNKNOWN = -1,
	ITEM = 0,
	DROP,
}

enum FilterTab
{
	ALL = 0,
	EQUIPMENT,
	USABLE,
	COMMON,
	QUEST
}

var selectedTile : CellTile				= null
var dropValue : int						= 1
var buttonMode : ButtonMode				= ButtonMode.UNKNOWN
var currentFilter : FilterTab			= FilterTab.ALL

#
func IsFiltered(cell : ItemCell, filter : FilterTab) -> bool:
	if not cell:
		return false

	match filter:
		FilterTab.ALL: return true
		FilterTab.EQUIPMENT: return cell.slot >= ActorCommons.Slot.FIRST_EQUIPMENT and cell.slot <= ActorCommons.Slot.LAST_EQUIPMENT
		FilterTab.USABLE: return cell.usable
		FilterTab.COMMON: return cell.slot == ActorCommons.Slot.NONE and not cell.usable
		FilterTab.QUEST: return cell.slot == ActorCommons.Slot.QUEST
	return false

func RefreshInventory():
	var count : int			= 0
	var tileIdx : int		= 0
	var tile : CellTile		= grid.GetTile(tileIdx)

	for item in Launcher.Player.inventory.items:
		if not item or item.cellID == DB.UnknownHash:
			continue

		var cell : ItemCell = DB.GetItem(item.cellID, item.cellCustomfield)
		if not cell:
			continue

		count += 1
		CellTile.RefreshShortcuts(cell, item.count)
		if IsFiltered(cell, currentFilter):
			if cell.stackable:
				if tile:
					tile.AssignData(cell, item.count)
					tileIdx += 1
					tile = grid.GetTile(tileIdx)
				else:
					break
			else:
				for cellIdx in item.count:
					if tile:
						tile.AssignData(cell)
						tileIdx += 1
						tile = grid.GetTile(tileIdx)
					else:
						break
		elif selectedTile and item and cell == selectedTile.cell:
			SelectTile(null)
			selectedTile = null

	for remainingIdx in range(tileIdx, grid.maxCount):
		grid.tiles[remainingIdx].AssignData(null, 0)

	for slot in range(ActorCommons.Slot.FIRST_EQUIPMENT, ActorCommons.Slot.LAST_EQUIPMENT):
		equipmentSlots[slot - ActorCommons.Slot.FIRST_EQUIPMENT].AssignData(Launcher.Player.inventory.equipment[slot - ActorCommons.Slot.FIRST_EQUIPMENT])

	RefreshModifiers(count)
	SelectTile(selectedTile if selectedTile else grid.GetTile(0))

func MakeModifierBBCode(effect : CellCommons.Modifier, value : Variant) -> String:
	var lightColor : String = "#" + UICommons.LightTextColor.to_html(false)
	var rawValue : String = CellCommons.FormatModifierValue(effect, value)
	var val : float = float(value)
	var arrow : String = " ↑" if val > 0.0 else (" ↓" if val < 0.0 else "")
	var arrowColor : String = "#" + UICommons.ModifierPositiveColor.to_html(false) if val > 0.0 else ("#" + UICommons.ModifierNegativeColor.to_html(false) if val < 0.0 else "")
	if arrowColor.is_empty():
		return "[color=%s]%s[/color]" % [lightColor, rawValue]
	return "[color=%s]%s[/color][color=%s]%s[/color]" % [lightColor, rawValue, arrowColor, arrow]

func GetEquipmentModifierTotals() -> Dictionary:
	var totals : Dictionary = {}
	for slot in range(ActorCommons.Slot.FIRST_EQUIPMENT, ActorCommons.Slot.LAST_EQUIPMENT):
		var equippedCell : ItemCell = Launcher.Player.inventory.equipment[slot - ActorCommons.Slot.FIRST_EQUIPMENT]
		if equippedCell and equippedCell.modifiers:
			for modifier in equippedCell.modifiers._modifiers:
				if modifier and modifier._persistent:
					if not totals.has(modifier._effect):
						totals[modifier._effect] = 0
					totals[modifier._effect] += modifier._value
	return totals

func RefreshModifiers(count : int = 0):
	if not Launcher.Player or not Launcher.Player.inventory:
		return
	var totals : Dictionary = GetEquipmentModifierTotals()
	var bbcode : String = ""
	var lightColor : String = "#" + UICommons.LightTextColor.to_html(false)
	for effect in totals:
		bbcode += "[color=%s]%s[/color]: %s\n" % [lightColor, CellCommons.GetModifierDisplayName(effect), MakeModifierBBCode(effect, totals[effect])]
	modifiersText.text = bbcode.strip_edges()
	RefreshCapacity(count)

func RefreshCapacity(_count : int = 0):
	if not Launcher.Player:
		return
	var count : int = _count if _count > 0 else CountInventoryItems()
	weightBar.SetStat(Launcher.Player.stat.weight, Launcher.Player.stat.current.weightCapacity)
	slotsBar.SetStat(count, ActorCommons.InventorySize)

func CountInventoryItems() -> int:
	if not Launcher.Player or not Launcher.Player.inventory:
		return 0
	var count : int = 0
	for item in Launcher.Player.inventory.items:
		if item and item.cellID != DB.UnknownHash:
			count += 1
	return count

func SelectTile(tile : CellTile):
	if selectedTile != tile:
		if selectedTile:
			selectedTile.RemoveSelection()
		selectedTile = tile if tile else grid.GetTile(0)
		if selectedTile:
			selectedTile.AddSelection()
	RefreshItemMode()

func RefreshItemMode():
	itemButtons.set_visible(true)
	dropButtons.set_visible(false)

	if selectedTile and selectedTile.cell and selectedTile.count > 0:
		var isEquipment : bool = selectedTile.cell.slot >= ActorCommons.Slot.FIRST_EQUIPMENT and selectedTile.cell.slot < ActorCommons.Slot.LAST_EQUIPMENT
		var isEquiped : bool = isEquipment and ActorCommons.IsEquipped(selectedTile.cell)
		var isQuestItem : bool = selectedTile.cell.slot == ActorCommons.Slot.QUEST

		useButton.set_visible(selectedTile.cell.usable)
		dropButton.set_visible(not isQuestItem)
		dropButton.set_disabled(false)
		equipButton.set_visible(isEquipment and not isEquiped)
		unequipButton.set_visible(isEquipment and isEquiped)
	else:
		dropButton.set_visible(false)
		useButton.set_visible(false)
		equipButton.set_visible(false)
		unequipButton.set_visible(false)

	if not dropButton.is_visible() and not useButton.is_visible() and not equipButton.is_visible() and not unequipButton.is_visible():
		dropButton.set_visible(true)
		dropButton.set_disabled(true)

func SetButtonMode(mode : ButtonMode):
	buttonMode = mode
	match mode:
		ButtonMode.ITEM:
			RefreshItemMode()
		ButtonMode.DROP:
			ResetDropButtons()
			RefreshDropMode()
		_: assert(false, "Unknown button mode within the inventory window")

func ResetDropButtons():
	dropValue = 1

func RefreshDropMode():
	itemButtons.set_visible(false)
	dropButtons.set_visible(true)

	dropValue = clamp(dropValue, 0, selectedTile.count)
	lessDropButton.set_disabled(dropValue <= 1)
	moreDropButton.set_disabled(dropValue >= selectedTile.count)
	dropLabel.set_text(str(dropValue))

#
func Connect():
	if not Launcher.Player:
		return
	Callback.PlugCallback(Launcher.Player.stat.vital_stats_updated, RefreshCapacity)

func _ready():
	for tileIdx in grid.maxCount:
		var tile : CellTile = grid.GetTile(tileIdx)
		if tile:
			tile.selected.connect(SelectTile)
	SetButtonMode(ButtonMode.ITEM)
	_post_launch()

func _post_launch():
	if Launcher.Map:
		if not Launcher.Map.PlayerWarped.is_connected(Connect):
			Launcher.Map.PlayerWarped.connect(Connect)

func _on_visibility_changed():
	if visible and grid:
		SelectTile(grid.GetTile(0))

func _on_use_pressed():
	if selectedTile and selectedTile.count > 0 and selectedTile.cell:
		Network.UseItem(selectedTile.cell.id)

func _on_equip_pressed():
	if selectedTile and selectedTile.cell:
		Network.EquipItem(selectedTile.cell.id, selectedTile.cell.customfield)

func _on_unequip_pressed():
	if selectedTile and selectedTile.cell:
		Network.UnequipItem(selectedTile.cell.id, selectedTile.cell.customfield)

func _on_drop_pressed():
	if selectedTile:
		if selectedTile.count == 1:
			ResetDropButtons()
			_on_confirm_drop_pressed()
		else:
			SetButtonMode(ButtonMode.DROP)

func _on_drop_cancel_pressed():
	SetButtonMode(ButtonMode.ITEM)

func _on_drop_less_pressed():
	dropValue -= 1
	RefreshDropMode()

func _on_drop_more_pressed():
	dropValue += 1
	RefreshDropMode()

func _on_confirm_drop_pressed():
	if selectedTile and selectedTile.cell:
		Network.DropItem(selectedTile.cell.id, selectedTile.cell.customfield, dropValue)
	SetButtonMode(ButtonMode.ITEM)

func _on_info_scroll_gui_input(event : InputEvent):
	Launcher.Action.TryConsume(event, "gp_zoom_in")
	Launcher.Action.TryConsume(event, "gp_zoom_out")

func _on_tab_container_tab_changed(tab : int):
	currentFilter = tab as FilterTab
	RefreshInventory()
