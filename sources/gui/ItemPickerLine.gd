extends HBoxContainer
class_name ItemPickerLine

#
signal value_changed

#
@onready var tile : CellTile		= $Tile
@onready var nameLabel : Label		= $Details/Name
@onready var priceLabel : Label		= $Details/Controls/Price
@onready var minusButton : Button	= $Details/Controls/Minus
@onready var plusButton : Button	= $Details/Controls/Plus
@onready var valueEdit : LineEdit	= $Details/Controls/Value

#
var cell : BaseCell					= null
var maxValue : int					= 0
var value : int						= 0

#
func Setup(lineCell : BaseCell, lineMax : int, lineValue : int, ownedCount : int = -1, price : int = -1):
	cell = lineCell
	maxValue = maxi(lineMax, 0)

	tile.isInteractive = false
	tile.AssignData(cell, maxi(ownedCount, 1))

	var title : String = cell.name
	if cell is ItemCell and not cell.customfield.is_empty():
		title += " (%s)" % cell.customfield
	nameLabel.set_text(title)
	priceLabel.set_text("%s GP" % Util.GetCompactNumber(price) if price >= 0 else "")

	SetValue(lineValue)

func SetValue(newValue : int):
	newValue = clampi(newValue, 0, maxValue)
	valueEdit.set_text(str(newValue))
	minusButton.set_disabled(newValue <= 0)
	plusButton.set_disabled(newValue >= maxValue)
	nameLabel.add_theme_color_override("font_color", UICommons.LightTextColor if newValue > 0 else UICommons.TextColor)
	if value != newValue:
		value = newValue
		value_changed.emit()
		queue_redraw()

func FocusChanged(isFocused : bool):
	tile.Hover(isFocused)
	nameLabel.modulate = Color(1.2, 1.2, 1.2) if isFocused else Color.WHITE
	queue_redraw()

func OnApplyEditedValue(_text : String = ""):
	SetValue(valueEdit.get_text().to_int())

func OnEditingToggled(isEditing : bool):
	Launcher.Action.Enable(not isEditing)

func _on_minus_pressed():
	SetValue(value - 1)

func _on_plus_pressed():
	SetValue(value + 1)

#
func _draw():
	if value > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(UICommons.DarkTextColor, 0.5))
	if has_focus():
		draw_rect(Rect2(Vector2.ZERO, size), Color(UICommons.CellTileColorHovered, 0.25))

func _exit_tree():
	if valueEdit.is_editing():
		OnEditingToggled(false)

func _gui_input(event : InputEvent):
	if event.is_action_pressed("ui_left", true):
		SetValue(value - 1)
		accept_event()
	elif event.is_action_pressed("ui_right", true):
		SetValue(value + 1)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		valueEdit.grab_focus()
		valueEdit.select_all()
		accept_event()
