extends Control

@onready var _icon : Button					= $Icon
@onready var _label : Label					= $Label

var _data : ContextData						= null
var _menu : ContextMenu						= null

#
func Init(data : ContextData, menu : ContextMenu):
	_data = data
	_menu = menu

func SetInputLabel():
	if DeviceManager.HasEvent(_data._action):
		var actionInfo : Array = DeviceManager.GetActionInfo(_data._action)
		if actionInfo.size() == DeviceManager.ActionInfo.COUNT:
			match actionInfo[DeviceManager.ActionInfo.DEVICE_TYPE]:
				DeviceManager.DeviceType.KEYBOARD:
					_icon.set_theme_type_variation("KeyTip")
				DeviceManager.DeviceType.JOYSTICK:
					_icon.set_theme_type_variation("ButtonTip")
				_:
					assert(false, "Device Type not recognized")
			_icon.set_text(actionInfo[DeviceManager.ActionInfo.NAME])

#
func _ready():
	_label.set_text(_data._title)
	SetInputLabel()
	Launcher.Action.deviceChanged.connect(SetInputLabel)
	if _icon:
		_icon.set_process_input(true)

func _on_visibility_changed():
	var isEnabled = is_visible_in_tree()
	set_process_input(isEnabled)
	if _icon:
		_icon.set_process_input(isEnabled)

func _unhandled_input(event):
	if not visible or not _data or _data._action.is_empty() or _data._callback.is_null():
		return
	if event.is_action(_data._action):
		if Launcher.Action.TryJustPressed(event, _data._action, true):
			_on_trigger()

func _on_trigger():
	if not visible or not _data or _data._action.is_empty() or _data._callback.is_null():
		return

	_data._callback.call()
	Launcher.Action.ConsumeAction(_data._action)
	if _menu:
		_menu.Hide()
