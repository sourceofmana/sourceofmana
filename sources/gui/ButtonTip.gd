extends Button
class_name ButtonTip

@export var action : StringName = ""

#
func UpdateTip():
	if InputMap.has_action(action):
		set_text(DeviceManager.GetActionInfo(action)[DeviceManager.ActionInfo.NAME])
	set_visible(get_text().length() > 0)

#
func _ready():
	Util.Assert(InputMap.has_action(action) == true, "Action not found! Could not process this button tip")
	UpdateTip()
