extends Control

#
@onready var leftButton : Button		= $ButtonLeft
@onready var middleButton : Button		= $ButtonMiddle
@onready var rightButton : Button		= $ButtonRight

# Private functions
func _bind(button : Button, buttonName : String, callable : Callable):
	Callback.OneShotCallback(button.pressed, callable)
	button.set_text(buttonName)
	button.set_visible(true)

func _clear(button : Button):
	button.set_visible(false)
	button.set_text("")
	Callback.ClearOneShot(button.pressed)

# Public functions
func SetLeft(buttonName : String, callable : Callable):
	_bind(leftButton, buttonName, callable)

func SetMiddle(buttonName : String, callable : Callable):
	_bind(middleButton, buttonName, callable)

func SetRight(buttonName : String, callable : Callable):
	_bind(rightButton, buttonName, callable)

func ClearAll():
	_clear(leftButton)
	_clear(middleButton)
	_clear(rightButton)

# Overriden
func _ready():
	ClearAll()
