extends Object
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

static var joyButton : Array = ["A", "B", "X", "Y", "Back", "Guide", "Start", "LSB", "RSB", "L", "R", "UP", "DOWN", "LEFT", "RIGHT", "Misc", "Paddle1", "Paddle2", "Paddle3", "Paddle4", "Touch"]
static var actionNames : Dictionary = {
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
	"ui_inventory" : "Inventory",
	"ui_close" : "Close",
	"ui_minimap" : "Minimap",
	"ui_chat" : "Chat",
	"ui_validate" : "Validate",
	"gp_click_to" : "Click To",
	"ui_screenshot" : "Screenshot",
	"gp_interact" : "Interact",
	"ui_emote" : "Emote",
	"smile_1" : "Emote",
	"smile_2" : "Emote",
	"smile_3" : "Emote",
	"smile_4" : "Emote",
	"smile_5" : "Emote",
	"smile_6" : "Emote",
	"smile_7" : "Emote",
	"smile_8" : "Emote",
	"smile_9" : "Emote",
	"smile_10" : "Emote",
	"smile_11" : "Emote",
	"smile_12" : "Emote",
	"smile_13" : "Emote",
	"smile_14" : "Emote",
	"smile_15" : "Emote",
	"smile_16" : "Emote",
	"smile_17" : "Emote",
	"gp_morph" : "Morph",
	"ui_settings" : "Settings",
	"ui_stat": "Stat",
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
	"ui_skill": "Skill",
	"ui_accept": "Accept",
	"ui_cancel": "Cancel",
	"ui_context_validate": "Context Validate",
	"ui_context_cancel": "Context Cancel",
	"ui_context_secondary": "Context Secondary",
	"ui_context_tertiary": "Context Tertiary"
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
			if not LauncherCommons.isMobile and currentDeviceType == DeviceType.KEYBOARD and event is InputEventKey:
				var keycode : Key = KEY_NONE
				if not LauncherCommons.isMobile:
					keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
				if keycode == KEY_NONE:
					keycode = event.keycode
				defaultValue = OS.get_keycode_string(keycode)
				break
			elif currentDeviceType == DeviceType.JOYSTICK and event is InputEventJoypadButton:
				var inScope : bool = event.button_index >= 0 and event.button_index < joyButton.size()
				defaultValue = joyButton[event.button_index] if inScope else str(event.button_index)
				break

	return [defaultValue, defaultDeviceType]

static func HasActionName(action : String) -> bool:
	return action in actionNames

static func GetActionName(action : String) -> String:
	return actionNames[action] if HasActionName(action) else ""

static func GetEvents(action : String) -> Array:
	return ProjectSettings.get_setting("input/" + action).events if ProjectSettings.has_setting("input/" + action) else []

static func HasEvent(action : String) -> bool:
	return GetEvents(action).size() > 0

static func HasDeviceSupport() -> bool:
	return DisplayServer.get_name() != "headless"

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
	currentDeviceType = deviceType

	if not LauncherCommons.isMobile:
		Launcher.Action.deviceChanged.emit()
