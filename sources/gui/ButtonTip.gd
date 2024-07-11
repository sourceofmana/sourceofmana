extends Button
class_name ButtonTip

@export var _action : StringName = ""
@export var _callback : Callable

#
func UpdateTip():
	if DeviceManager.HasEvent(_action):
		set_text(DeviceManager.GetActionInfo(_action)[DeviceManager.ActionInfo.NAME])
	set_visible(get_text().length() > 0)

func Setup(action : StringName, callback : Callable):
	_action = action
	_callback = callback
	UpdateTip()

#
func _input(event):
	if not visible:
		return

	if event.is_action_pressed(_action):
		_callback.call()
		Launcher.Action.ConsumeAction(_action)
		get_viewport().set_input_as_handled()
