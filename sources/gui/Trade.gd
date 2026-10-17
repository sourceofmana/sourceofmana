extends WindowPanel

#
@onready var ownName : Label				= $Layout/Margin/Content/Header/Own
@onready var otherName : Label				= $Layout/Margin/Content/Header/Other

@onready var ownColumn : Control			= $Layout/Margin/Content/Items/Own
@onready var ownScroll : ScrollContainer	= $Layout/Margin/Content/Items/Own/Scroll
@onready var ownGrid : GridContainer		= $Layout/Margin/Content/Items/Own/Scroll/Grid
@onready var picker : ItemPicker			= $Layout/Margin/Content/Items/Own/ItemPicker
@onready var ownOverlay : Control			= $Layout/Margin/Content/Items/Own/LockOverlay

@onready var otherScroll : ScrollContainer	= $Layout/Margin/Content/Items/Other/Scroll
@onready var otherGrid : GridContainer		= $Layout/Margin/Content/Items/Other/Scroll/Grid
@onready var otherPicker : ItemPicker		= $Layout/Margin/Content/Items/Other/ItemPicker
@onready var otherOverlay : Control			= $Layout/Margin/Content/Items/Other/LockOverlay

@onready var gpBox : Container				= $Layout/Margin/Content/GP/Picker
@onready var gpMinusButton : Button			= $Layout/Margin/Content/GP/Picker/Minus
@onready var gpPlusButton : Button			= $Layout/Margin/Content/GP/Picker/Plus
@onready var gpEdit : LineEdit				= $Layout/Margin/Content/GP/Picker/Value

@onready var otherGPBox : Container			= $Layout/Margin/Content/GP/Other
@onready var otherGP : Label				= $Layout/Margin/Content/GP/Other/Value

@onready var gpSeparator : Control			= $Layout/Margin/Content/GP/Separator
@onready var balanceBox : Container			= $Layout/Margin/Content/GP/Balance
@onready var balanceValue : Label			= $Layout/Margin/Content/GP/Balance/Value

@onready var statusLabel : Label			= $Layout/Margin/Content/Footer/Status
@onready var doneButton : Button			= $Layout/Margin/Content/Footer/Done
@onready var lockButton : Button			= $Layout/Margin/Content/Footer/Lock
@onready var cancelButton : Button			= $Layout/Margin/Content/Footer/Cancel

#
const lockedColor : Color					= Color(0.5, 0.5, 0.5)
const lockCooldown : float					= 3.0

#
var addButton : Button						= null
var gpOffer : int							= 0

var ownOffer : Array						= []
var otherOffer : Array						= []

var ownGPValue : int						= 0
var otherGPValue : int						= 0

var revision : int							= 0
var lockCooldownLeft : float				= 0.0
var isTrading : bool						= false
var ownLocked : bool						= false
var otherLocked : bool						= false

var isMerchant : bool						= false
var stockPrices : Dictionary				= {}
var sellPrices : Dictionary					= {}

#
func IsTrading() -> bool:
	return isTrading

func Open(nick : String):
	isMerchant = false
	Start(nick)

func OpenMerchant(nick : String, newStockPrices : Dictionary, newSellPrices : Dictionary):
	isMerchant = true
	stockPrices = newStockPrices
	sellPrices = newSellPrices
	Start(nick)

func Start(nick : String):
	ownOffer = []
	otherOffer = []

	ownGPValue = 0
	otherGPValue = 0

	revision = 0
	lockCooldownLeft = 0.0
	isTrading = true
	ownLocked = false
	otherLocked = false

	ownName.size_flags_stretch_ratio = 1.0 if isMerchant else 1.5
	ownColumn.size_flags_stretch_ratio = 1.0 if isMerchant else 1.5
	gpBox.size_flags_stretch_ratio = 1.0 if isMerchant else 1.5

	otherName.set_text(nick)
	otherScroll.set_visible(not isMerchant)
	otherPicker.set_visible(isMerchant)
	otherPicker.Clear()
	if isMerchant:
		otherPicker.Fill(GetStockEntries())

	ClosePicker()
	Refresh()

	EnableControl(true)

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
	var balance : int = GetMerchantBalance() if isMerchant else otherGPValue - ownGPValue
	balanceValue.set_text(("+" if balance > 0 else "") + Util.GetCompactNumber(balance))
	balanceValue.add_theme_color_override("font_color", UICommons.ModifierPositiveColor if balance > 0 else UICommons.ModifierNegativeColor if balance < 0 else UICommons.LightTextColor)

	var ownCount : int = FillGrid(ownGrid, ownOffer)
	FillGrid(otherGrid, otherOffer)
	if addButton:
		addButton.set_visible(not ownLocked and ownCount < ActorCommons.TradeMaxItems)

	otherGP.set_text(Util.GetCompactNumber(otherGPValue))
	ownOverlay.set_visible(ownLocked)
	otherOverlay.set_visible(otherLocked)
	otherGPBox.modulate = lockedColor if otherLocked else Color.WHITE

	RefreshLockButton()
	if isMerchant:
		statusLabel.set_text("Not enough GP." if not CanAffordMerchant() else "")
	elif ownLocked and otherLocked:
		statusLabel.set_text("Completing the trade...")
	elif ownLocked:
		statusLabel.set_text("Waiting for partner...")
	elif otherLocked:
		statusLabel.set_text("Partner locked.")
	else:
		statusLabel.set_text("")

func RefreshLockButton():
	if isMerchant:
		lockButton.set_disabled(not CanAffordMerchant() or (ownOffer.is_empty() and otherPicker.GetValues().is_empty()))
		lockButton.set_text("Trade")
		return

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

	if not isMerchant:
		SetGPOffer(ownGPValue)

	SetPickerVisible(true)
	picker.Focus(focusCell)

func ApplyPicker():
	var entries : Array = GetPickerEntries()
	if isMerchant:
		ownOffer = entries
		ClosePicker()
		Refresh()
	else:
		Network.TradeSetOffer(entries, gpOffer)
		ClosePicker()

func ClosePicker():
	SetPickerVisible(false)
	picker.Clear()

func SetGPOffer(newValue : int):
	gpOffer = clampi(newValue, 0, Launcher.Player.stat.gp)
	gpEdit.set_text(str(gpOffer))
	gpMinusButton.set_disabled(gpOffer <= 0)
	gpPlusButton.set_disabled(gpOffer >= Launcher.Player.stat.gp)

func SetPickerVisible(state : bool):
	picker.set_visible(state)
	var isEditingGP : bool = state and not isMerchant
	gpBox.set_visible(isEditingGP)
	gpSeparator.set_visible(isEditingGP)
	otherGPBox.set_visible(isEditingGP)
	balanceBox.set_visible(not isEditingGP)
	doneButton.set_visible(state)
	ownScroll.set_visible(not state)
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
		if not cell or cell.slot == ActorCommons.Slot.QUEST or (isMerchant and not sellPrices.has(cell.id)):
			continue

		var existingEntry : Dictionary = {}
		for entry in entries:
			if CellCommons.IsSameCell(entry["cell"], cell):
				existingEntry = entry
				break

		var itemCount : int = item.count if cell.stackable else 1
		if existingEntry.is_empty():
			entries.append({"cell": cell, "max": itemCount, "owned": itemCount, "price": sellPrices.get(cell.id, -1) if isMerchant else -1})
		else:
			existingEntry["max"] += itemCount
			existingEntry["owned"] += itemCount

	return entries

func GetStockEntries() -> Array[Dictionary]:
	var entries : Array[Dictionary] = []
	for itemID in stockPrices:
		if DB.ItemsDB.has(itemID):
			entries.append({"cell": DB.GetItem(itemID), "max": ActorCommons.MerchantMaxItemCount, "price": stockPrices[itemID]})
	return entries

func GetBuyEntries() -> Array:
	var entries : Array = []
	for value in otherPicker.GetValues():
		entries.append([value[0].id, value[1], ""])
	return entries

func GetPickerEntries() -> Array:
	var entries : Array = []
	for value in picker.GetValues():
		var cell : ItemCell = value[0]
		entries.append([cell.id, value[1], cell.customfield])
	return entries

func GetMerchantBalance() -> int:
	var balance : int = 0
	var sellEntries : Array = GetPickerEntries() if picker.is_visible() else ownOffer
	for entry in sellEntries:
		balance += sellPrices.get(entry[0], 0) * entry[1]
	for value in otherPicker.GetValues():
		balance -= stockPrices.get(value[0].id, 0) * value[1]
	return balance

func CanAffordMerchant() -> bool:
	return Launcher.Player.stat.gp + GetMerchantBalance() >= 0

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
	if isMerchant:
		Network.MerchantTrade(ownOffer, GetBuyEntries())
	else:
		Network.TradeLock(revision, not ownLocked)

func _on_cancel_pressed():
	if picker.is_visible():
		ClosePicker()
		Refresh()
	else:
		Network.TradeCancel()
		Close()

func _on_done_pressed():
	ApplyPicker()

func OnGPEdited(_text : String = ""):
	SetGPOffer(gpEdit.get_text().to_int())

func OnGPEditingToggled(isEditing : bool):
	Launcher.Action.Enable(not isEditing)

func _on_gp_minus_pressed():
	SetGPOffer(gpOffer - 1)

func _on_gp_plus_pressed():
	SetGPOffer(gpOffer + 1)

func OnPickerChanged():
	if isMerchant:
		Refresh()

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

	otherPicker.values_changed.connect(Refresh)
	picker.values_changed.connect(OnPickerChanged)
	SetPickerVisible(false)
	set_process(false)

func _process(delta : float):
	lockCooldownLeft = maxf(lockCooldownLeft - delta, 0.0)
	if lockCooldownLeft <= 0.0:
		set_process(false)
	RefreshLockButton()
