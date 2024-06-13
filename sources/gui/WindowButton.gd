extends Button

@export var targetWindow : Control = null
@export var targetShortcut : StringName = ""

func OnTopButtonPressed():
	if targetWindow:
		Launcher.GUI.ToggleControl(targetWindow)

func _ready():
	if targetShortcut:
		var eventList : Array = DeviceManager.GetEvents(targetShortcut)
		if eventList.size() > 0:
			shortcut = Shortcut.new()
			shortcut.events = eventList
			tooltip_text = tooltip_text + " " + name
