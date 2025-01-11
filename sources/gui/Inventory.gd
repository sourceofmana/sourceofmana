extends WindowPanel

@onready var weightStat : Control		= $Margin/VBoxContainer/Bars/WeightTex/ProgressBar
@onready var slotStat : Control			= $Margin/VBoxContainer/Bars/SlotTex/ProgressBar
@onready var grid : GridContainer		= $Margin/VBoxContainer/Container/Margin/Grid

@onready var itemButtons : Control		= $Margin/VBoxContainer/ItemButtons
@onready var dropButtons : Control		= $Margin/VBoxContainer/DropButtons

@onready var dropButton : Button		= $Margin/VBoxContainer/ItemButtons/Drop
@onready var useButton : Button			= $Margin/VBoxContainer/ItemButtons/Use
@onready var equipButton : Button		= $Margin/VBoxContainer/ItemButtons/Equip
@onready var unequipButton : Button		= $Margin/VBoxContainer/ItemButtons/Unequip

@onready var lessDropButton : Button	= $Margin/VBoxContainer/DropButtons/Less
@onready var moreDropButton : Button	= $Margin/VBoxContainer/DropButtons/More
@onready var dropLabel : Label			= $Margin/VBoxContainer/DropButtons/Label

enum ButtonMode
{
	UNKNOWN = -1,
	ITEM = 0,
	DROP,
}

var selectedTile : CellTile				= null
var dropValue : int						= 1
var buttonMode : ButtonMode				= ButtonMode.UNKNOWN

#
func RefreshInventory():
	var count : int			= 0
	var tileIdx : int		= 0
	var tile : CellTile		= grid.tiles[tileIdx]

	for item in Launcher.Player.inventory.items:
		if item and item.cell:
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

	for remainingIdx in range(tileIdx, grid.maxCount):
		grid.tiles[remainingIdx].AssignData(null, 0)

	weightStat.SetStat(Formula.GetWeight(Launcher.Player.inventory), Launcher.Player.stat.current.weightCapacity)
	slotStat.SetStat(count, ActorCommons.InventorySize)

	SelectTile(selectedTile)

func SelectTile(tile : CellTile):
	if selectedTile and selectedTile != tile:
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
		useButton.set_visible(selectedTile.cell.usable)
		dropButton.set_visible(true)
		equipButton.set_visible(isEquipment and not isEquiped)
		unequipButton.set_visible(isEquipment and isEquiped)
	else:
		dropButton.set_visible(false)
		useButton.set_visible(false)
		equipButton.set_visible(false)
		unequipButton.set_visible(false)

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
