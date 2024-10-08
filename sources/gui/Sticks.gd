extends HBoxContainer

#
@onready var DirectionButton : Control			= $Direction/Direction/Button
@onready var DefaultStickPosition : Vector2		= DirectionButton.get_position()

var leftStickPressed : bool				= false
var lastMove : Vector2 = Vector2.ZERO

#
func GetMove() -> Vector2:
	if leftStickPressed and DefaultStickPosition.x != 0.0 and DefaultStickPosition.y != 0.0:
		var move : Vector2 = DirectionButton.get_position() / DefaultStickPosition - Vector2.ONE
		lastMove = move
		return move
	else:
		return Vector2.ZERO

#
func _on_direction_button_down():
	leftStickPressed = true

func _on_direction_button_up():
	leftStickPressed = false
	DirectionButton.position = DefaultStickPosition

func _physics_process(_delta):
	if leftStickPressed:
		var newPos : Vector2 = get_local_mouse_position() - DirectionButton.get_size() / 2
		newPos.x = clampf(newPos.x, 0.0, 100.0)
		newPos.y = clampf(newPos.y, 0.0, 100.0)

		DirectionButton.position = newPos

func _press_button(buttonId : JoyButton):
	DeviceManager.SendEventJoy(buttonId, true)

func _release_button(buttonId : JoyButton):
	DeviceManager.SendEventJoy(buttonId, false)
