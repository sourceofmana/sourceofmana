extends Control

#
@onready var leftButton : Button		= $ButtonLeft
@onready var middleButton : Button		= $ButtonMiddle
@onready var rightButton : Button		= $ButtonRight

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
		UICommons.ButtonBox.LEFT:		_bind(leftButton, buttonName, callable)
		UICommons.ButtonBox.MIDDLE:		_bind(middleButton, buttonName, callable)
		UICommons.ButtonBox.RIGHT:		_bind(rightButton, buttonName, callable)
		_:								assert(false, "Unknown button box side")

func Call(side : UICommons.ButtonBox):
	match side:
		UICommons.ButtonBox.LEFT:		_call(leftButton)
		UICommons.ButtonBox.MIDDLE:		_call(middleButton)
		UICommons.ButtonBox.RIGHT:		_call(rightButton)
		_:								assert(false, "Unknown button box side")

func Rename(side : UICommons.ButtonBox, buttonName : String):
	match side:
		UICommons.ButtonBox.LEFT:		_name(leftButton, buttonName)
		UICommons.ButtonBox.MIDDLE:		_name(middleButton, buttonName)
		UICommons.ButtonBox.RIGHT:		_name(rightButton, buttonName)
		_:								assert(false, "Unknown button box side")

func Clear(side : UICommons.ButtonBox):
	match side:
		UICommons.ButtonBox.LEFT:		_clear(leftButton)
		UICommons.ButtonBox.MIDDLE:		_clear(middleButton)
		UICommons.ButtonBox.RIGHT:		_clear(rightButton)
		_:								assert(false, "Unknown button box side")

func Focus(side : UICommons.ButtonBox):
	match side:
		UICommons.ButtonBox.LEFT:		_focus(leftButton)
		UICommons.ButtonBox.MIDDLE:		_focus(middleButton)
		UICommons.ButtonBox.RIGHT:		_focus(rightButton)
		_:								assert(false, "Unknown button box side")

func ClearAll():
	_clear(leftButton)
	_clear(middleButton)
	_clear(rightButton)

# Overriden
func _ready():
	ClearAll()
