extends HBoxContainer

#
@onready var buttonLeft : TouchScreenButton		= $LeftAnchor/ButtonLeft
@onready var direction : TouchScreenButton		= $LeftAnchor/Direction
@onready var buttonRight : TouchScreenButton	= $RightAnchor/ButtonRight
@onready var actions : Control					= $RightAnchor/Actions

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

func Enable(isEnabled : bool):
	if isEnabled:
		var rescaledWindowSize : float = float(DisplayServer.window_get_size().x / Launcher.Root.get_content_scale_factor())
		var horizontalMargin : int = lerp(0, 160, max(0, rescaledWindowSize - Launcher.GUI.settingsWindow.GetVal("Render-MinWindowSize").x * 1.5) / rescaledWindowSize)
		Launcher.GUI.shortcuts.add_theme_constant_override("margin_left", horizontalMargin)
		Launcher.GUI.shortcuts.add_theme_constant_override("margin_right", horizontalMargin)

	buttonLeft.set_visible(isEnabled)
	direction.set_visible(isEnabled)
	buttonRight.set_visible(isEnabled)
	actions.set_visible(isEnabled)

	if Launcher.Action:
		Launcher.Action.supportMouse = not isEnabled

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
