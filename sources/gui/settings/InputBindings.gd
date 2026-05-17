extends TabContainer
class_name InputBindings

#
const actionCategories : Dictionary[StringName, Array] = {
	"Movement": [
		"gp_move_up", "gp_move_down", "gp_move_left", "gp_move_right",
	],
	"Target": [
		"gp_interact", "gp_target", "gp_untarget",
	],
	"Gameplay": [
		"gp_sit", "gp_run", "gp_pickup", "gp_morph",
	],
	"Interface": [
		"ui_validate", "ui_close", "ui_stat", "ui_menu",
		"ui_inventory", "ui_skill", "ui_chat", "ui_minimap",
		"ui_emote", "ui_settings", "ui_progress", "ui_social",
	],
	"Context": [
		"ui_context_validate", "ui_context_cancel",
		"ui_context_secondary", "ui_context_tertiary",
	],
	"System": [
		"ui_screenshot", "ui_fullscreen",
	],
	"Shortcuts": [
		"gp_shortcut_1", "gp_shortcut_2", "gp_shortcut_3", "gp_shortcut_4",
		"gp_shortcut_5", "gp_shortcut_6", "gp_shortcut_7", "gp_shortcut_8",
		"gp_shortcut_9", "gp_shortcut_10",
	],
	"Emotes": [
		"smile_1", "smile_2", "smile_3", "smile_4", "smile_5",
		"smile_6", "smile_7", "smile_8", "smile_9", "smile_10",
		"smile_11", "smile_12", "smile_13", "smile_14", "smile_15",
		"smile_16", "smile_17",
	],
}

const confSection : String = "User"
const confKeyPrefix : String = "Input-"

const touchButtons : Array[Array] = [
	[JOY_BUTTON_A, "A"],
	[JOY_BUTTON_B, "B"],
	[JOY_BUTTON_X, "X"],
	[JOY_BUTTON_Y, "Y"],
	[JOY_BUTTON_LEFT_SHOULDER, "L"],
	[JOY_BUTTON_RIGHT_SHOULDER, "R"],
]

# Rebinding state
var rebindingAction : String = ""
var rebindingDeviceType : DeviceManager.DeviceType = DeviceManager.DeviceType.KEYBOARD
var rebindingButton : Button = null
var rebindingOriginalText : String = ""
var rebindTimer : Timer = null
var rebindCountdown : int = 0

#
func _ready():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	visibility_changed.connect(_on_visibility_changed)
	set_process_input(false)

func _on_visibility_changed():
	if is_visible():
		Rebuild()
	else:
		CancelRebinding()

func _on_joy_connection_changed(_deviceId : int, _connected : bool):
	if is_visible():
		Rebuild()

# Rebinding (Keyboard / Joystick)
func StartRebinding(action : String, deviceType : DeviceManager.DeviceType, button : Button):
	CancelRebinding()
	rebindingAction = action
	rebindingDeviceType = deviceType
	rebindingOriginalText = button.text
	rebindingButton = button

	Launcher.Action.Enable(false)

	rebindCountdown = 5
	UpdateButtonPrompt()
	StartCountdown()
	set_process_input(true)

func UpdateButtonPrompt():
	if rebindingButton:
		rebindingButton.text = "... (%d)" % rebindCountdown

func StartCountdown():
	StopCountdown()
	rebindTimer = Timer.new()
	rebindTimer.wait_time = 1.0
	rebindTimer.timeout.connect(_on_rebind_tick)
	add_child(rebindTimer)
	rebindTimer.start()

func StopCountdown():
	if rebindTimer:
		rebindTimer.stop()
		rebindTimer.queue_free()
		rebindTimer = null

func _on_rebind_tick():
	rebindCountdown -= 1
	if rebindCountdown <= 0:
		CancelRebinding()
		return
	UpdateButtonPrompt()

func CancelRebinding():
	if rebindingAction.is_empty():
		return
	if rebindingButton:
		rebindingButton.text = rebindingOriginalText
	rebindingButton = null
	rebindingAction = ""
	rebindingOriginalText = ""
	StopCountdown()
	set_process_input(false)

	Launcher.Action.Enable(true)

func _input(event : InputEvent):
	if rebindingAction.is_empty() or not event.is_pressed():
		return

	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		CancelRebinding()
		return

	var validEvent : bool = false
	match rebindingDeviceType:
		DeviceManager.DeviceType.KEYBOARD:
			validEvent = event is InputEventKey or event is InputEventMouseButton
		DeviceManager.DeviceType.JOYSTICK:
			validEvent = event is InputEventJoypadButton or event is InputEventJoypadMotion

	if not validEvent:
		return

	if event is InputEventJoypadMotion:
		if absf(event.axis_value) < 0.5:
			return
		event.axis_value = 1.0 if event.axis_value > 0 else -1.0

	get_viewport().set_input_as_handled()
	ApplyRebinding(rebindingAction, event)

func IsSameEvent(eventA : InputEvent, eventB : InputEvent) -> bool:
	if eventA is InputEventKey and eventB is InputEventKey:
		return eventA.keycode == eventB.keycode and eventA.physical_keycode == eventB.physical_keycode
	if eventA is InputEventMouseButton and eventB is InputEventMouseButton:
		return eventA.button_index == eventB.button_index
	if eventA is InputEventJoypadButton and eventB is InputEventJoypadButton:
		return eventA.button_index == eventB.button_index
	if eventA is InputEventJoypadMotion and eventB is InputEventJoypadMotion:
		return eventA.axis == eventB.axis and signf(eventA.axis_value) == signf(eventB.axis_value)
	return false

static func MatchesDeviceType(event : InputEvent, deviceType : DeviceManager.DeviceType) -> bool:
	return DeviceManager.MatchesDeviceType(event, deviceType)

func ApplyRebinding(action : String, newEvent : InputEvent):
	var deviceType : DeviceManager.DeviceType = rebindingDeviceType
	var oldEvent : InputEvent = null
	for event in DeviceManager.GetEvents(action):
		if MatchesDeviceType(event, deviceType):
			oldEvent = event
			break

	if oldEvent:
		InputMap.action_erase_event(action, oldEvent)
	InputMap.action_add_event(action, newEvent)

	var button : Button = rebindingButton
	CancelRebinding()
	if button:
		button.text = GetBindingText(action, deviceType)

# Touch rebinding (combobox)
func ApplyTouchRebinding(selectedIdx : int, action : String):
	for event in DeviceManager.GetEvents(action):
		if event is InputEventJoypadButton:
			InputMap.action_erase_event(action, event)

	if selectedIdx > 0 and selectedIdx <= touchButtons.size():
		var newEvent := InputEventJoypadButton.new()
		newEvent.button_index = touchButtons[selectedIdx - 1][0]
		InputMap.action_add_event(action, newEvent)

# (Re-)Build UI
func Rebuild():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	BuildDeviceTab("Keyboard", DeviceManager.DeviceType.KEYBOARD, false)

	var joypads : Array[int] = Input.get_connected_joypads()
	for deviceId in joypads:
		var joyName : String = Input.get_joy_name(deviceId)
		if joyName.is_empty():
			joyName = "Controller %d" % deviceId
		BuildDeviceTab(joyName, DeviceManager.DeviceType.JOYSTICK, false)

	BuildDeviceTab("Touch", DeviceManager.DeviceType.JOYSTICK, true)

func BuildDeviceTab(tabName : String, deviceType : DeviceManager.DeviceType, isTouch : bool) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tabName
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_right", 12)
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	for category in actionCategories:
		BuildCategory(vbox, category, actionCategories[category], deviceType, isTouch)

	var resetButton := Button.new()
	resetButton.text = "Reset to Default"
	resetButton.pressed.connect(ResetBindings.bind(deviceType))
	vbox.add_child(resetButton)

	add_child(scroll)
	return scroll

func BuildCategory(parent : VBoxContainer, categoryName : String, actions : PackedStringArray, deviceType : DeviceManager.DeviceType, isTouch : bool):
	var header := Label.new()
	header.text = categoryName
	parent.add_child(header)

	for action in actions:
		if not DeviceManager.HasActionName(action):
			continue
		if isTouch:
			BuildTouchRow(parent, action, DeviceManager.GetActionName(action))
		else:
			var binding : String = GetBindingText(action, deviceType)
			BuildBindingRow(parent, action, DeviceManager.GetActionName(action), binding, deviceType)

	var spacerTop := Control.new()
	spacerTop.custom_minimum_size.y = 4
	parent.add_child(spacerTop)

	var separator := HSeparator.new()
	parent.add_child(separator)

	var spacerBottom := Control.new()
	spacerBottom.custom_minimum_size.y = 4
	parent.add_child(spacerBottom)

func BuildBindingRow(parent : VBoxContainer, action : String, actionName : String, binding : String, deviceType : DeviceManager.DeviceType):
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var nameLabel := Label.new()
	nameLabel.text = " " + actionName
	nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nameLabel)

	var bindingButton := Button.new()
	bindingButton.text = binding if not binding.is_empty() else "-"
	bindingButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bindingButton.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bindingButton.pressed.connect(StartRebinding.bind(action, deviceType, bindingButton))
	row.add_child(bindingButton)

	parent.add_child(row)

func BuildTouchRow(parent : VBoxContainer, action : String, actionName : String):
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var nameLabel := Label.new()
	nameLabel.text = " " + actionName
	nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nameLabel)

	var combo := OptionButton.new()
	combo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combo.add_item("-")
	for entry in touchButtons:
		combo.add_item(entry[1])

	# Pre-select the correct value
	var currentIdx : int = 0
	for event in DeviceManager.GetEvents(action):
		if event is InputEventJoypadButton:
			for i in touchButtons.size():
				if touchButtons[i][0] == event.button_index:
					currentIdx = i + 1
					break
			break
	combo.selected = currentIdx
	combo.item_selected.connect(ApplyTouchRebinding.bind(action))
	row.add_child(combo)

	parent.add_child(row)

# Persistence
static func GetDeviceSuffix(deviceType : DeviceManager.DeviceType) -> String:
	return "-kb" if deviceType == DeviceManager.DeviceType.KEYBOARD else "-joy"

static func FilterEvents(events : Array, deviceType : DeviceManager.DeviceType) -> Array[InputEvent]:
	var filtered : Array[InputEvent] = []
	for event in events:
		if event is InputEvent and MatchesDeviceType(event, deviceType):
			filtered.append(event)
	return filtered

static func LoadBindings():
	for category in actionCategories:
		for action in actionCategories[category]:
			for deviceType in [DeviceManager.DeviceType.KEYBOARD, DeviceManager.DeviceType.JOYSTICK]:
				var key : String = confKeyPrefix + action + GetDeviceSuffix(deviceType)
				var saved = Conf.GetVariant(confSection, key, Conf.Type.USERSETTINGS)
				if saved == null or saved is not String:
					continue
				var events = str_to_var(saved)
				if events is not Array:
					continue
				for existing in InputMap.action_get_events(action):
					if MatchesDeviceType(existing, deviceType):
						InputMap.action_erase_event(action, existing)
				for event in events:
					if event is InputEvent:
						InputMap.action_add_event(action, event)

static func SaveBindings():
	for category in actionCategories:
		for action in actionCategories[category]:
			var defaultEvents : Array = DeviceManager.GetDefaultEvents(action)
			for deviceType in [DeviceManager.DeviceType.KEYBOARD, DeviceManager.DeviceType.JOYSTICK]:
				var currentFiltered : Array[InputEvent] = FilterEvents(DeviceManager.GetEvents(action), deviceType)
				var defaultFiltered : Array[InputEvent] = FilterEvents(defaultEvents, deviceType)

				var key : String = confKeyPrefix + action + GetDeviceSuffix(deviceType)
				if HasBindingChanged(currentFiltered, defaultFiltered):
					Conf.SetValue(confSection, key, Conf.Type.USERSETTINGS, var_to_str(currentFiltered))

static func HasBindingChanged(current : Array[InputEvent], defaults : Array[InputEvent]) -> bool:
	if current.size() != defaults.size():
		return true
	for i in current.size():
		if var_to_str(current[i]) != var_to_str(defaults[i]):
			return true
	return false

# Reset
func ResetBindings(deviceType : DeviceManager.DeviceType):
	for category in actionCategories:
		for action in actionCategories[category]:
			var defaultEvents : Array = DeviceManager.GetDefaultEvents(action)

			for event in DeviceManager.GetEvents(action):
				if MatchesDeviceType(event, deviceType):
					InputMap.action_erase_event(action, event)

			for event in defaultEvents:
				if MatchesDeviceType(event, deviceType):
					InputMap.action_add_event(action, event)

	Rebuild()

# Binding text
func GetBindingText(action : String, deviceType : DeviceManager.DeviceType) -> String:
	var bindings : PackedStringArray = []
	for event in DeviceManager.GetEvents(action):
		if MatchesDeviceType(event, deviceType):
			var text : String = DeviceManager.GetEventName(event)
			if not text.is_empty():
				bindings.append(text)
	return ", ".join(bindings)
