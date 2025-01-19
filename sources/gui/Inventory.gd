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

@onready var weightStat : Control		= $Margin/HBoxContainer/InfoBox/Bars/WeightTex/ProgressBar
@onready var slotStat : Control			= $Margin/HBoxContainer/InfoBox/Bars/SlotTex/ProgressBar

@onready var equipmentSlots : Array[CellTile] = [
	null, # Body
	null, # Face
	null, # Hair
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Chest,
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Legs,
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Feet,
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Hands,
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Head,
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Neck,
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Weapon,
	$Margin/HBoxContainer/InfoBox/EquipmentGrid/Shield,
]

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
		FilterTab.QUEST: return cell.slot == ActorCommons.Slot.NONE and not cell.usable and not cell.stackable
	return false

func RefreshInventory():
	var count : int			= 0
	var tileIdx : int		= 0
	var tile : CellTile		= grid.GetTile(tileIdx)

	for item in Launcher.Player.inventory.items:
		if item and item.cell and IsFiltered(item.cell, currentFilter):
			count += 1
			CellTile.RefreshShortcuts(item.cell, item.count)
			if item.cell.stackable:
				if tile:
					tile.AssignData(item.cell, item.count)
					tileIdx += 1
					tile = grid.GetTile(tileIdx)
				else:
					break
			else:
				for cellIdx in range(item.count):
					if tile:
						tile.AssignData(item.cell)
						tileIdx += 1
						tile = grid.GetTile(tileIdx)
					else:
						break
		elif selectedTile and item and item.cell == selectedTile.cell:
			SelectTile(null)
			selectedTile = null

	for remainingIdx in range(tileIdx, grid.maxCount):
		grid.tiles[remainingIdx].AssignData(null, 0)

	weightStat.SetStat(Formula.GetWeight(Launcher.Player.inventory), Launcher.Player.stat.current.weightCapacity)
	slotStat.SetStat(count, ActorCommons.InventorySize)

	for slot in range(ActorCommons.Slot.FIRST_EQUIPMENT, ActorCommons.Slot.LAST_EQUIPMENT):
		equipmentSlots[slot].AssignData(Launcher.Player.inventory.equipments[slot])

	SelectTile(selectedTile if selectedTile else grid.GetTile(0))

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
		var isEquipment : bool = selectedTile.cell.slot != ActorCommons.Slot.NONE
		var isEquiped : bool = isEquipment and Launcher.Player.inventory.equipments[selectedTile.cell.slot] == selectedTile.cell
		var isQuestItem : bool = selectedTile.cell.slot == ActorCommons.Slot.NONE and not selectedTile.cell.usable and not selectedTile.cell.stackable
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
func _ready():
	for tileIdx in range(grid.maxCount):
		var tile : CellTile = grid.GetTile(tileIdx)
		if tile:
			tile.selected.connect(SelectTile)
	SetButtonMode(ButtonMode.ITEM)

func _on_visibility_changed():
	if visible and grid:
		SelectTile(grid.GetTile(0))

func _on_use_pressed():
	if selectedTile and selectedTile.count > 0 and selectedTile.cell and selectedTile.cell:
		Network.UseItem(selectedTile.cell.id)

func _on_equip_pressed():
	if selectedTile and selectedTile.cell:
		Network.EquipItem(selectedTile.cell.id)

func _on_unequip_pressed():
	if selectedTile and selectedTile.cell:
		Network.UnequipItem(selectedTile.cell.id)

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
		Network.DropItem(selectedTile.cell.id, dropValue)
	SetButtonMode(ButtonMode.ITEM)

func _on_tab_container_tab_changed(tab : int):
	currentFilter = tab as FilterTab
	RefreshInventory()
