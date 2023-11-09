extends HBoxContainer

#
@onready var DirectionButton : Control			= $Direction/Button
@onready var DefaultStickPosition : Vector2		= DirectionButton.get_position()

var leftStickPressed : bool				= false
var lastMove : Vector2 = Vector2.ZERO

#
func GetMove() -> Vector2:
	if leftStickPressed:
		var move : Vector2 = DirectionButton.get_position() / DefaultStickPosition - Vector2.ONE
		lastMove = move
		return move
	else:
		return Vector2.ZERO

#
func _on_button_y_pressed():
	if Launcher.Network:
		Launcher.Network.TriggerSit()

func _on_button_b_pressed():
	if Launcher.Network:
		Launcher.Network.TriggerEmote(3)

func _on_button_x_pressed():
	if Launcher.GUI:
		Launcher.Network.TriggerMorph()

func _on_button_a_pressed():
	if Launcher.Player:
		Launcher.Player.Interact()

func _on_direction_button_down():
	leftStickPressed = true

func _on_direction_button_up():
	leftStickPressed = false
	DirectionButton.position = DefaultStickPosition

func _physics_process(_delta):
	if leftStickPressed:
#		DirectionButton.global_position = get_global_mouse_position() - DirectionButton.get_size() / 2

		var newPos : Vector2 = get_local_mouse_position() - DirectionButton.get_size() / 2
		newPos.x = clampf(newPos.x, 0.0, 100.0)
		newPos.y = clampf(newPos.y, 0.0, 100.0)

		DirectionButton.position = newPos


#		newPos = clampPos + DirectionButton.get_global_position()

#		DirectionButton.set_global_position(newPos)


