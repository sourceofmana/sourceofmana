extends Object
class_name DeviceManager

static var useJoystick : bool = 0
static var joyButton : Array = ["A", "B", "X", "Y", "Back", "Guide", "Start", "LSB", "RSB", "LB", "RB", "UP", "DOWN", "LEFT", "RIGHT", "Misc", "Paddle1", "Paddle2", "Paddle3", "Paddle4", "Touch"]

#
static func Init():
	Input.joy_connection_changed.connect(ConnectionChanged)
	ConnectionChanged()

static func ConnectionChanged(_deviceId : int = 0, _connected : bool = false):
	useJoystick = Input.get_connected_joypads().size() > 0

static func GetButtonName(actionName : String) -> String:
	for event in InputMap.action_get_events(actionName):
		if not useJoystick and event is InputEventKey:
			return OS.get_keycode_string(event.key_label)
		if useJoystick and event is InputEventJoypadButton:
			return joyButton[event.button_index] if event.button_index > 0 and event.button_index < joyButton.size() else event.button_index
	return ""
