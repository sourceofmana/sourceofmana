extends PanelContainer

#
@onready var otherName : Label				= $Layout/Margin/Content/Header/Other
@onready var ownScroll : ScrollContainer	= $Layout/Margin/Content/Items/Own/Scroll
@onready var ownGrid : GridContainer		= $Layout/Margin/Content/Items/Own/Scroll/Grid
@onready var picker : ItemPicker			=$Layout/Margin/Content/Items/Own/ItemPicker
@onready var ownOverlay : Control			= $Layout/Margin/Content/Items/Own/LockOverlay
@onready var otherGrid : GridContainer		= $Layout/Margin/Content/Items/Other/Scroll/Grid
@onready var otherEmpty : Label				= $Layout/Margin/Content/Items/Other/Empty
@onready var otherOverlay : Control			= $Layout/Margin/Content/Items/Other/LockOverlay
@onready var ownGPBox : Container			= $Layout/Margin/Content/GP/Own
@onready var ownGP : Label					= $Layout/Margin/Content/GP/Own/Value
@onready var gpBox : Container				= $Layout/Margin/Content/GP/Picker
@onready var otherGPBox : Container			= $Layout/Margin/Content/GP/Other
@onready var otherGP : Label				= $Layout/Margin/Content/GP/Other/Value
@onready var statusLabel : Label			= $Layout/Margin/Content/Footer/Status
@onready var doneButton : Button			= $Layout/Margin/Content/Footer/Done
@onready var lockButton : Button			= $Layout/Margin/Content/Footer/Lock
@onready var cancelButton : Button			= $Layout/Margin/Content/Footer/Cancel

#
const lockedColor : Color					= Color(0.5, 0.5, 0.5)
const lockCooldown : float					= 3.0

#
var addButton : Button						= null
var gpLine : ItemPickerLine					= null

var otherNick : String						= ""
var ownOffer : Array						= []
var otherOffer : Array						= []

var ownGPValue : int						= 0
var otherGPValue : int						= 0

var revision : int							= 0
var lockCooldownLeft : float				= 0.0
var isTrading : bool						= false
var ownLocked : bool						= false
var otherLocked : bool						= false

#
func IsTrading() -> bool:
	return isTrading

func Open(nick : String):
	otherNick = nick

	ownOffer = []
	otherOffer = []

	ownGPValue = 0
	otherGPValue = 0

	revision = 0
	lockCooldownLeft = 0.0
	isTrading = true
	ownLocked = false
	otherLocked = false

	otherName.set_text(nick)

	ClosePicker()
	Refresh()
	set_visible(true)

	if not Launcher.GUI.inventoryWindow.is_visible():
		Launcher.GUI.ToggleControl(Launcher.GUI.inventoryWindow)

func Close(reason : String = ""):
	isTrading = false
	ClosePicker()
	set_visible(false)
	if not reason.is_empty():
		Launcher.GUI.notificationLabel.AddNotification(reason)

func UpdateOffers(newOwnOffer : Array, newOwnGP : int, newOtherOffer : Array, newOtherGP : int, newOwnLocked : bool, newOtherLocked : bool, newRevision : int):
	if newOtherOffer != otherOffer or newOtherGP != otherGPValue:
		lockCooldownLeft = lockCooldown
		set_process(true)

	ownOffer = newOwnOffer
	ownGPValue = newOwnGP
	otherOffer = newOtherOffer
	otherGPValue = newOtherGP
	ownLocked = newOwnLocked
	otherLocked = newOtherLocked
	revision = newRevision

	Refresh()

#
func Refresh():
	var ownCount : int = FillGrid(ownGrid, ownOffer)
	FillGrid(otherGrid, otherOffer)
	if addButton:
		addButton.set_visible(not ownLocked and ownCount < ActorCommons.TradeMaxItems)

	ownGP.set_text(Util.GetFormatedText(str(ownGPValue)))
	otherGP.set_text(Util.GetFormatedText(str(otherGPValue)))
	otherEmpty.set_visible(otherOffer.is_empty() and otherGPValue == 0 and not otherLocked)
	ownOverlay.set_visible(ownLocked)
	otherOverlay.set_visible(otherLocked)
	ownGPBox.modulate = lockedColor if ownLocked else Color.WHITE
	otherGPBox.modulate = lockedColor if otherLocked else Color.WHITE

	RefreshLockButton()
	if ownLocked and otherLocked:
		statusLabel.set_text("Completing the trade...")
	elif ownLocked:
		statusLabel.set_text("Waiting for %s to lock." % otherNick)
	elif otherLocked:
		statusLabel.set_text("%s locked their offer." % otherNick)
	else:
		statusLabel.set_text("")

func RefreshLockButton():
	var isCoolingDown : bool = lockCooldownLeft > 0.0 and not ownLocked
	lockButton.set_disabled(isCoolingDown)

	if isCoolingDown:
		lockButton.set_text("Lock (%d)" % ceili(lockCooldownLeft))
	else:
		lockButton.set_text("Unlock" if ownLocked else "Lock")

func FillGrid(grid : GridContainer, offer : Array) -> int:
	var tileIdx : int = 0
	for entry in offer:
		var tile : CellTile = grid.GetTile(tileIdx)
		var cell : ItemCell = GetEntryCell(entry)
		if tile and cell:
			tile.AssignData(cell, entry[1])
			tileIdx += 1

	var filledCount : int = tileIdx
	var remainingTile : CellTile = grid.GetTile(tileIdx)
	while remainingTile:
		remainingTile.AssignData(null, 0)
		tileIdx += 1
		remainingTile = grid.GetTile(tileIdx)

	return filledCount

# Picker
func OpenPicker(focusCell : BaseCell = null, increment : int = 0):
	if not isTrading or ownLocked:
		return

	if picker.is_visible():
		var line : ItemPickerLine = picker.GetLine(focusCell)
		if line:
			line.SetValue(line.value + increment)
		picker.Focus(focusCell)
		return

	var entries : Array[Dictionary] = GetInventoryEntries()
	for entry in entries:
		entry["value"] = GetOfferCount(ownOffer, entry["cell"])
		if increment != 0 and CellCommons.IsSameCell(entry["cell"], focusCell):
			entry["value"] += increment
	picker.Fill(entries)

	if gpLine:
		gpLine.queue_free()
	gpLine = ItemPickerLine.new(null, Launcher.Player.stat.gp, ownGPValue, "GP")
	gpBox.add_child(gpLine)

	SetPickerVisible(true)
	picker.Focus(focusCell)

func ApplyPicker():
	var entries : Array = []
	for value in picker.GetValues():
		var cell : ItemCell = value[0]
		entries.append([cell.id, value[1], cell.customfield])

	Network.TradeSetOffer(entries, gpLine.value if gpLine else ownGPValue)
	ClosePicker()

func ClosePicker():
	SetPickerVisible(false)
	picker.Clear()
	if gpLine:
		gpLine.queue_free()
		gpLine = null

func SetPickerVisible(state : bool):
	picker.set_visible(state)
	gpBox.set_visible(state)
	doneButton.set_visible(state)
	ownScroll.set_visible(not state)
	ownGPBox.set_visible(not state)
	lockButton.set_visible(not state)
	cancelButton.set_text("Back" if state else "Cancel")

func RefreshInventory():
	if picker.is_visible():
		var currentValues : Array = picker.GetValues()
		var focusedLine : ItemPickerLine = get_viewport().gui_get_focus_owner() as ItemPickerLine
		var entries : Array[Dictionary] = GetInventoryEntries()
		for entry in entries:
			for value in currentValues:
				if CellCommons.IsSameCell(entry["cell"], value[0]):
					entry["value"] = value[1]

		picker.Fill(entries)
		if focusedLine and focusedLine.cell:
			picker.Focus(focusedLine.cell)

# Helpers
func GetInventoryEntries() -> Array[Dictionary]:
	var entries : Array[Dictionary] = []
	for item in Launcher.Player.inventory.items:
		if not item or Launcher.Player.inventory.IsItemEquipped(item):
			continue

		var cell : ItemCell = DB.GetItem(item.cellID, item.cellCustomfield)
		if not cell or cell.slot == ActorCommons.Slot.QUEST:
			continue

		var existingEntry : Dictionary = {}
		for entry in entries:
			if CellCommons.IsSameCell(entry["cell"], cell):
				existingEntry = entry
				break

		var itemCount : int = item.count if cell.stackable else 1
		if existingEntry.is_empty():
			entries.append({"cell": cell, "max": itemCount, "owned": itemCount})
		else:
			existingEntry["max"] += itemCount
			existingEntry["owned"] += itemCount

	return entries

static func GetEntryCell(entry : Array) -> ItemCell:
	if entry.size() == 3 and DB.ItemsDB.has(entry[0]):
		return DB.GetItem(entry[0], entry[2])
	return null

static func GetOfferCount(offer : Array, cell : BaseCell) -> int:
	for entry in offer:
		if entry.size() == 3 and CellCommons.CompareCell(cell, entry[0], entry[2]):
			return entry[1]
	return 0

# Signals
func _on_lock_pressed():
	Network.TradeLock(revision, not ownLocked)

func _on_cancel_pressed():
	if picker.is_visible():
		ClosePicker()
	else:
		Network.TradeCancel()
		Close()

func _on_done_pressed():
	ApplyPicker()

func OnOwnTileSelected(tile : CellTile):
	OpenPicker(tile.cell)

#
func _ready():
	addButton = Button.new()
	addButton.set_text("+")
	addButton.custom_minimum_size = Vector2(34, 34)
	addButton.pressed.connect(OpenPicker)
	ownGrid.add_child.call_deferred(addButton)

	var tileIdx : int = 0
	var tile : CellTile = ownGrid.GetTile(tileIdx)
	while tile:
		tile.selected.connect(OnOwnTileSelected)
		tileIdx += 1
		tile = ownGrid.GetTile(tileIdx)

	SetPickerVisible(false)
	set_process(false)

func _process(delta : float):
	lockCooldownLeft = maxf(lockCooldownLeft - delta, 0.0)
	if lockCooldownLeft <= 0.0:
		set_process(false)
	RefreshLockButton()
