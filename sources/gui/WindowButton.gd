extends Button

@export var targetWindow : Control = null

func OnTopButtonPressed():
	if targetWindow:
		Launcher.GUI.ToggleControl(targetWindow)
