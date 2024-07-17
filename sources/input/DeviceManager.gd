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
static var useJoystick : bool = false
static var joyButton : Array = ["A", "B", "X", "Y", "Back", "Guide", "Start", "LSB", "RSB", "LB", "RB", "UP", "DOWN", "LEFT", "RIGHT", "Misc", "Paddle1", "Paddle2", "Paddle3", "Paddle4", "Touch"]

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
	"ui_skill": "Skill",
	"ui_cancel": "Cancel",
	"ui_secondary": "Secondary",
	"ui_tertiary": "Tertiary"
}

# Re-assign controller input events to first valid controller
#
# never use the touchpad as controller, this might need to be extended in the future
# as the godot issue also talks about LED controllers being mistaken for game controllers
#
# this workaround is needed because of https://github.com/godotengine/godot/issues/59250
static func UpdateWorkaroundTouchPad(_deviceID: int = -1, _connected: bool = false):
	var validControllerID : int = -1
	for device in Input.get_connected_joypads():
		if not Input.get_joy_name(device).contains("Touchpad"):
			validControllerID = device
			break

	# Reset
	InputMap.load_from_project_settings()

	if validControllerID != -1:
		# If valid controller is connected set it's device id so the touchpad is not used
		for action in InputMap.get_actions():
			for event in InputMap.action_get_events(action):
				if event is InputEventJoypadMotion or event is InputEventJoypadButton:
					InputMap.action_erase_event(action, event)
					event.device = validControllerID
					InputMap.action_add_event(action, event)
	else:
		# If no controller is connected then remove joystick events from actions
		for action in InputMap.get_actions():
			for event in InputMap.action_get_events(action):
				if event is InputEventJoypadMotion or event is InputEventJoypadButton:
					InputMap.action_erase_event(action, event)

#
static func Init():
	Input.joy_connection_changed.connect(DeviceManager.ConnectionChanged)
	for deviceId in Input.get_connected_joypads():
		ConnectionChanged(deviceId, true)
	if DeviceManager.HasDeviceSupport():
		Input.set_custom_mouse_cursor(FileSystem.LoadGfx("gui/misc/mouse.png"))

static func ConnectionChanged(deviceId : int, connected : bool):
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		useJoystick = true
	else:
		useJoystick = Input.get_connected_joypads().size() > 0

	if OS.get_name() == "Linux":
		UpdateWorkaroundTouchPad(deviceId, connected)

static func GetActionInfo(action : String) -> Array:
	var defaultValue : String = ""
	var defaultDeviceType : DeviceType = DeviceType.KEYBOARD

	if HasDeviceSupport():
		for event in GetEvents(action):
			if event is InputEventKey:
				var keycode : Key = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
				defaultValue = OS.get_keycode_string(keycode if keycode != 0 else event.keycode)
				defaultDeviceType = DeviceType.KEYBOARD
				if not useJoystick:
					break

			if event is InputEventJoypadButton:
				if event.button_index >= 0 and event.button_index < joyButton.size():
					defaultValue = joyButton[event.button_index]
				else:
					defaultValue = str(event.button_index)
				defaultDeviceType = DeviceType.JOYSTICK
				if useJoystick:
					break

	return [defaultValue, defaultDeviceType]

static func GetActionName(action : String) -> String:
	return actionNames[action] if actionNames.has(action) else ""

static func GetEvents(action : String) -> Array:
	return ProjectSettings.get_setting("input/" + action).events if ProjectSettings.has_setting("input/" + action) else []

static func HasEvent(action : String) -> bool:
	return GetEvents(action).size() > 0

static func HasDeviceSupport() -> bool:
	return DisplayServer.get_name() != "headless"
