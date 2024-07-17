extends Object
class_name ContextData

@export var _action : StringName
@export var _title : String
@export var _callback : Callable

#
func _init(action : StringName, title : String = "", callback : Callable = Callable()):
	_action = action
	_callback = callback
	_title = DeviceManager.GetActionName(action) if title == "" else title
