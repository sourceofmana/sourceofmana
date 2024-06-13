extends Button
class_name ButtonTip

@export var action : StringName = ""

#
func UpdateTip():
	if DeviceManager.HasEvent(action):
		set_text(DeviceManager.GetActionInfo(action)[DeviceManager.ActionInfo.NAME])
	set_visible(get_text().length() > 0)

#
func _ready():
	Util.Assert(DeviceManager.HasEvent(action) == true, "Action not found! Could not process this button tip")
	UpdateTip()
