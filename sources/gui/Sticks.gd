extends HBoxContainer

#
@onready var directionButton : Control			= $LeftAnchor/Direction/Button
@onready var defaultStickPosition : Vector2		= directionButton.get_position()

var leftStickPressed : bool				= false
var lastMove : Vector2 = Vector2.ZERO

#
func GetMove() -> Vector2:
	if leftStickPressed and defaultStickPosition.x != 0.0 and defaultStickPosition.y != 0.0:
		var move : Vector2 = directionButton.get_position() / defaultStickPosition - Vector2.ONE
		lastMove = move
		return move
	else:
		return Vector2.ZERO

#
func _on_direction_button_down():
	leftStickPressed = true

func _on_direction_button_up():
	leftStickPressed = false
	directionButton.position = defaultStickPosition

func _physics_process(_delta):
	if leftStickPressed:
		var newPos : Vector2 = get_local_mouse_position() - directionButton.get_size() / 2
		newPos.x = clampf(newPos.x, 0.0, 100.0)
		newPos.y = clampf(newPos.y, 0.0, 100.0)

		directionButton.position = newPos

func _press_button(buttonId : JoyButton):
	DeviceManager.SendEventJoy(buttonId, true)

func _release_button(buttonId : JoyButton):
	DeviceManager.SendEventJoy(buttonId, false)
