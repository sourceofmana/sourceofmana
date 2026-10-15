extends HBoxContainer
class_name ItemPickerLine

#
var cell : BaseCell					= null
var maxValue : int					= 0
var value : int						= 0

var tile : CellTile					= null
var nameLabel : Label				= null
var minusButton : Button			= null
var plusButton : Button				= null
var valueEdit : LineEdit			= null

const buttonSize : Vector2			= Vector2(28, 28)

#
func SetValue(newValue : int):
	newValue = clampi(newValue, 0, maxValue)
	valueEdit.set_text(str(newValue))
	minusButton.set_disabled(newValue <= 0)
	plusButton.set_disabled(newValue >= maxValue)
	value = newValue

func MakeButton(buttonText : String, callback : Callable) -> Button:
	var button : Button = Button.new()
	button.set_text(buttonText)
	button.custom_minimum_size = buttonSize
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button

func FocusChanged(isFocused : bool):
	if tile:
		tile.Hover(isFocused)
	nameLabel.modulate = Color(1.2, 1.2, 1.2) if isFocused else Color.WHITE

func OnApplyEditedValue(_text : String = ""):
	SetValue(valueEdit.get_text().to_int())

func OnEditingToggled(isEditing : bool):
	Launcher.Action.Enable(not isEditing)

#
func _init(lineCell : BaseCell, lineMax : int, lineValue : int, lineTitle : String = "", ownedCount : int = -1):
	cell = lineCell
	maxValue = maxi(lineMax, 0)
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if cell:
		tile = UICommons.CellTilePreset.instantiate()
		tile.isInteractive = false
		tile.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(tile)
		tile.AssignData.call_deferred(cell, 1)

	nameLabel = Label.new()
	if lineTitle.is_empty() and cell:
		lineTitle = cell.name
		if cell is ItemCell and not cell.customfield.is_empty():
			lineTitle += " (%s)" % cell.customfield
	nameLabel.set_text(lineTitle)
	nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nameLabel.clip_text = true
	add_child(nameLabel)

	if ownedCount >= 0:
		var ownedLabel : Label = Label.new()
		ownedLabel.set_text("x%d" % ownedCount)
		ownedLabel.add_theme_color_override("font_color", UICommons.LightTextColor)
		add_child(ownedLabel)

	minusButton = MakeButton("-", func(): SetValue(value - 1))
	add_child(minusButton)

	valueEdit = LineEdit.new()
	valueEdit.custom_minimum_size = Vector2(48, buttonSize.y)
	valueEdit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	valueEdit.text_submitted.connect(OnApplyEditedValue)
	valueEdit.focus_exited.connect(OnApplyEditedValue)
	valueEdit.editing_toggled.connect(OnEditingToggled)
	add_child(valueEdit)

	plusButton = MakeButton("+", func(): SetValue(value + 1))
	add_child(plusButton)

	SetValue(lineValue)

	focus_entered.connect(FocusChanged.bind(true))
	focus_exited.connect(FocusChanged.bind(false))

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
