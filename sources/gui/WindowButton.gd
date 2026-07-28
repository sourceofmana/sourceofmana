extends Control
class_name WindowButton

@export var targetWindow : Control = null
@export var targetShortcut : StringName = ""

#
func OnTopButtonPressed():
	if targetWindow:
		Launcher.GUI.ToggleControl(targetWindow)

func _ready():
	assert(targetWindow != null, "Invalid shortcut given for this window button")
	tooltip_text = tooltip_text + " " + name
