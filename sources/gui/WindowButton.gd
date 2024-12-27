extends Button

@export var targetWindow : Control = null
@export var targetShortcut : StringName = ""

func OnTopButtonPressed():
	if targetWindow:
		Launcher.GUI.ToggleControl(targetWindow)

func _ready():
	assert(targetWindow != null, "Invalid shortcut given for this window button")
	if targetWindow:
		var eventList : Array = DeviceManager.GetEvents(targetShortcut)
		assert(not eventList.is_empty(), "Invalid shortcut %s given for this window button" % targetShortcut)
		if not eventList.is_empty():
			shortcut = Shortcut.new()
			shortcut.events = eventList
			tooltip_text = tooltip_text + " " + name
