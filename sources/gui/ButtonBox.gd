extends Control

#
@onready var primaryButton : Button		= $ButtonPrimary
@onready var secondaryButton : Button	= $ButtonSecondary
@onready var tertiaryButton : Button	= $ButtonTertiary
@onready var cancelButton : Button		= $ButtonCancel

# Private functions
func _bind(button : Button, buttonName : String, callable : Callable):
	Callback.PlugCallback(button.pressed, callable)
	button.set_visible(true)
	_name(button, buttonName)

func _call(button : Button):
	button.pressed.emit()

func _name(button : Button, buttonName : String):
	button.set_text(buttonName)

func _clear(button : Button):
	button.set_visible(false)
	button.set_text("")
	Callback.ClearCallbacks(button.pressed)

func _focus(button : Button):
	if button.visible:
		button.grab_focus()

# Public functions
func Bind(side : UICommons.ButtonBox, buttonName : String, callable : Callable):
	match side:
		UICommons.ButtonBox.PRIMARY:	_bind(primaryButton, buttonName, callable)
		UICommons.ButtonBox.SECONDARY:	_bind(secondaryButton, buttonName, callable)
		UICommons.ButtonBox.TERTIARY:	_bind(tertiaryButton, buttonName, callable)
		UICommons.ButtonBox.CANCEL:		_bind(cancelButton, buttonName, callable)
		_:								assert(false, "Unknown button box side")

func Call(side : UICommons.ButtonBox):
	match side:
		UICommons.ButtonBox.PRIMARY:	_call(primaryButton)
		UICommons.ButtonBox.SECONDARY:	_call(secondaryButton)
		UICommons.ButtonBox.TERTIARY:	_call(tertiaryButton)
		UICommons.ButtonBox.CANCEL:		_call(cancelButton)
		_:								assert(false, "Unknown button box side")

func Rename(side : UICommons.ButtonBox, buttonName : String):
	match side:
		UICommons.ButtonBox.PRIMARY:	_name(primaryButton, buttonName)
		UICommons.ButtonBox.SECONDARY:	_name(secondaryButton, buttonName)
		UICommons.ButtonBox.TERTIARY:	_name(tertiaryButton, buttonName)
		UICommons.ButtonBox.CANCEL:		_name(cancelButton, buttonName)
		_:								assert(false, "Unknown button box side")

func Clear(side : UICommons.ButtonBox):
	match side:
		UICommons.ButtonBox.PRIMARY:	_clear(primaryButton)
		UICommons.ButtonBox.SECONDARY:	_clear(secondaryButton)
		UICommons.ButtonBox.TERTIARY:	_clear(tertiaryButton)
		UICommons.ButtonBox.CANCEL:		_clear(cancelButton)
		_:								assert(false, "Unknown button box side")

func Focus(side : UICommons.ButtonBox):
	match side:
		UICommons.ButtonBox.PRIMARY:	_focus(primaryButton)
		UICommons.ButtonBox.SECONDARY:	_focus(secondaryButton)
		UICommons.ButtonBox.TERTIARY:	_focus(tertiaryButton)
		UICommons.ButtonBox.CANCEL:		_focus(cancelButton)
		_:								assert(false, "Unknown button box side")

func ClearAll():
	_clear(primaryButton)
	_clear(secondaryButton)
	_clear(tertiaryButton)
	_clear(cancelButton)

#
func TrapFocus():
	var visibleButtons : Array[Button] = []
	var visibleButtonCount : int = 0
	for btn in [cancelButton, tertiaryButton, secondaryButton, primaryButton]:
		if btn and btn.visible:
			visibleButtons.append(btn)
			visibleButtonCount += 1

	if visibleButtonCount < 2:
		return

	for i in visibleButtonCount:
		var prev : Button = visibleButtons[(i - 1 + visibleButtonCount) % visibleButtonCount]
		var next : Button = visibleButtons[(i + 1) % visibleButtonCount]
		visibleButtons[i].focus_next = visibleButtons[i].get_path_to(next)
		visibleButtons[i].focus_previous = visibleButtons[i].get_path_to(prev)
		visibleButtons[i].focus_neighbor_left = visibleButtons[i].get_path_to(prev)
		visibleButtons[i].focus_neighbor_right = visibleButtons[i].get_path_to(next)
		visibleButtons[i].focus_neighbor_top = visibleButtons[i].get_path_to(prev)
		visibleButtons[i].focus_neighbor_bottom = visibleButtons[i].get_path_to(next)

func ReleaseFocus():
	for btn in [cancelButton, tertiaryButton, secondaryButton, primaryButton]:
		if btn:
			btn.focus_next = NodePath("")
			btn.focus_previous = NodePath("")
			btn.focus_neighbor_left = NodePath("")
			btn.focus_neighbor_right = NodePath("")
			btn.focus_neighbor_top = NodePath("")
			btn.focus_neighbor_bottom = NodePath("")

#
func HandleInput(event : InputEvent):
	if primaryButton and primaryButton.is_visible() and event.is_action("ui_context_validate"):
		if Launcher.Action.TryPressed(event, "ui_context_validate", true):
			_call(primaryButton)
	elif primaryButton and primaryButton.is_visible() and event.is_action("ui_validate"):
		if Launcher.Action.TryPressed(event, "ui_validate", true):
			_call(primaryButton)
	elif secondaryButton and secondaryButton.is_visible() and event.is_action("ui_context_secondary"):
		if Launcher.Action.TryPressed(event, "ui_context_secondary", true):
			_call(secondaryButton)
	elif tertiaryButton and tertiaryButton.is_visible() and event.is_action("ui_context_tertiary"):
		if Launcher.Action.TryPressed(event, "ui_context_tertiary", true):
			_call(tertiaryButton)
	elif cancelButton and cancelButton.is_visible() and event.is_action("ui_context_cancel"):
		if Launcher.Action.TryPressed(event, "ui_context_cancel", true):
			_call(cancelButton)
	elif cancelButton and cancelButton.is_visible() and event.is_action("ui_cancel"):
		if Launcher.Action.TryPressed(event, "ui_cancel", true):
			_call(cancelButton)

# Overriden
func _ready():
	ClearAll()

func _unhandled_input(event : InputEvent):
	if not visible or not Launcher.Action.IsEnabled():
		return

	HandleInput(event)
