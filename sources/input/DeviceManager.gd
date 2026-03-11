extends RefCounted
class_name DeviceManager

#
enum DeviceType
{
	KEYBOARD = 0,
	JOYSTICK
}

enum ActionInfo
{
	NAME = 0,
	DEVICE_TYPE,
	COUNT
}

#
static var currentDeviceId : int = -1
static var currentDeviceType : DeviceType = DeviceType.JOYSTICK if LauncherCommons.isMobile else DeviceType.KEYBOARD

static var joyButton : PackedStringArray = ["A", "B", "X", "Y", "Back", "Guide", "Start", "LSB", "RSB", "L", "R", "UP", "DOWN", "LEFT", "RIGHT", "Misc", "Paddle1", "Paddle2", "Paddle3", "Paddle4", "Touch"]
static var actionNames : Dictionary[String, String] = {
	"ui_select" : "Select",
	"ui_focus_next" : "Focus Next",
	"ui_focus_prev" : "Focus Previous",
	"ui_page_up" : "Page Up",
	"ui_page_down" : "Page Down",
	"ui_home" : "Home",
	"ui_end" : "End",
	"ui_menu" : "Menu",
	"gp_sit" : "Sit",
	"gp_move_up" : "Move Up",
	"gp_move_down" : "Move Down",
	"gp_move_left" : "Move Left",
	"gp_move_right" : "Move Right",
	"ui_inventory" : "Inventory Window",
	"ui_close" : "Close",
	"ui_minimap" : "Minimap Window",
	"ui_chat" : "Chat Window",
	"ui_validate" : "Validate",
	"gp_click_to" : "Click To",
	"ui_screenshot" : "Screenshot",
	"gp_interact" : "Interact",
	"ui_emote" : "Emote Window",
	"smile_1" : "Dying",
	"smile_2" : "Creeped",
	"smile_3" : "Smile",
	"smile_4" : "Sad",
	"smile_5" : "Evil",
	"smile_6" : "Wink",
	"smile_7" : "Angel",
	"smile_8" : "Embarrassed",
	"smile_9" : "Amused",
	"smile_10" : "Grin",
	"smile_11" : "Angry",
	"smile_12" : "Bored",
	"smile_13" : "Bubble",
	"smile_14" : "Dots",
	"smile_15" : "Whatever",
	"smile_16" : "Surprised",
	"smile_17" : "Confused",
	"gp_morph" : "Morph",
	"ui_settings" : "Settings",
	"ui_stat": "Stat Window",
	"ui_progress": "Progress Window",
	"ui_credits": "Credits Window",
	"ui_fullscreen": "Toggle Fullscreen",
	"gp_shortcut_1" : "Shortcut 1",
	"gp_shortcut_2" : "Shortcut 2",
	"gp_shortcut_3" : "Shortcut 3",
	"gp_shortcut_4" : "Shortcut 4",
	"gp_shortcut_5" : "Shortcut 5",
	"gp_shortcut_6" : "Shortcut 6",
	"gp_shortcut_7" : "Shortcut 7",
	"gp_shortcut_8" : "Shortcut 8",
	"gp_shortcut_9" : "Shortcut 9",
	"gp_shortcut_10" : "Shortcut 10",
	"gp_target" : "Target",
	"gp_untarget" : "Clear Target",
	"gp_pickup" : "Pickup",
	"gp_run" : "Run",
	"ui_skill": "Skill Window",
	"ui_accept": "Accept",
	"ui_cancel": "Cancel",
	"ui_context_validate": "Context Validate",
	"ui_context_cancel": "Context Cancel",
	"ui_context_secondary": "Context Secondary",
	"ui_context_tertiary": "Context Tertiary",
	"gp_zoom_in": "Zoom In",
	"gp_zoom_out": "Zoom Out",
	"gp_zoom_reset": "Reset Zoom",
}

#
static func Init():
	if DeviceManager.HasDeviceSupport():
		Input.set_custom_mouse_cursor(FileSystem.LoadGfx("gui/misc/mouse.png"))

static func GetActionInfo(action : String) -> Array:
	var defaultValue : String = ""
	var defaultDeviceType : DeviceType = DeviceType.KEYBOARD

	if HasDeviceSupport():
		for event in GetEvents(action):
			if MatchesDeviceType(event, currentDeviceType):
				defaultValue = GetEventName(event)
				if not defaultValue.is_empty():
					break

	return [defaultValue, defaultDeviceType]

static func MatchesDeviceType(event : InputEvent, deviceType : DeviceType) -> bool:
	match deviceType:
		DeviceType.KEYBOARD:
			return event is InputEventKey or event is InputEventMouseButton
		DeviceType.JOYSTICK:
			return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return false

static func HasActionName(action : String) -> bool:
	return action in actionNames

static func GetActionName(action : String) -> String:
	return actionNames[action] if HasActionName(action) else ""

static func GetEvents(action : String) -> Array[InputEvent]:
	return InputMap.action_get_events(action) if InputMap.has_action(action) else []

static func GetDefaultEvents(action : String) -> Array:
	return ProjectSettings.get_setting("input/" + action).events if ProjectSettings.has_setting("input/" + action) else []

static func HasEvent(action : String) -> bool:
	return not GetEvents(action).is_empty()

static func HasDeviceSupport() -> bool:
	return DisplayServer.get_name() != "headless"

static func GetEventName(event : InputEvent) -> String:
	if event is InputEventKey:
		if event.keycode:
			return event.as_text_keycode()
		elif event.physical_keycode:
			return event.as_text_physical_keycode()
	elif event is InputEventMouseButton:
		return GetMouseButtonName(event.button_index)
	elif event is InputEventJoypadButton:
		return GetJoyButtonName(event.button_index)
	elif event is InputEventJoypadMotion:
		return GetJoyAxisName(event.axis, event.axis_value)
	return ""

static func GetJoyButtonName(buttonIndex : int) -> String:
	if buttonIndex >= 0 and buttonIndex < joyButton.size():
		return joyButton[buttonIndex]
	return str(buttonIndex)

static func GetMouseButtonName(buttonIndex : MouseButton) -> String:
	match buttonIndex:
		MOUSE_BUTTON_LEFT:		return "Mouse Left"
		MOUSE_BUTTON_RIGHT:		return "Mouse Right"
		MOUSE_BUTTON_MIDDLE:	return "Mouse Middle"
		MOUSE_BUTTON_WHEEL_UP:	return "Mouse Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN:return "Mouse Wheel Down"
		_:						return "Mouse %d" % buttonIndex

static func GetJoyAxisName(axis : JoyAxis, value : float) -> String:
	var axisName : String = ""
	match axis:
		JOY_AXIS_LEFT_X:		axisName = "Left Stick X"
		JOY_AXIS_LEFT_Y:		axisName = "Left Stick Y"
		JOY_AXIS_RIGHT_X:		axisName = "Right Stick X"
		JOY_AXIS_RIGHT_Y:		axisName = "Right Stick Y"
		JOY_AXIS_TRIGGER_LEFT:	axisName = "Left Trigger"
		JOY_AXIS_TRIGGER_RIGHT:	axisName = "Right Trigger"
		_:						axisName = "Axis %d" % axis
	if value > 0:
		axisName += "+"
	elif value < 0:
		axisName += "-"
	return axisName

#
static func SendEvent(action : String, state : bool = true):
	var event = InputEventJoypadButton.new()
	event.action = action
	event.pressed = state
	Input.parse_input_event(event)

static func SendEventJoy(buttonID : int, state : bool = true):
	var event = InputEventJoypadButton.new()
	event.pressed = state
	event.button_index = buttonID
	event.pressure = 1.0 if state else 0.0
	Input.parse_input_event(event)

#
static func DeviceChanged(deviceType : DeviceType):
	if LauncherCommons.isMobile:
		return

	currentDeviceType = deviceType
	Launcher.Action.deviceChanged.emit()
