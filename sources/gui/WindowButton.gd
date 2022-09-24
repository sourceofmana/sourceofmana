extends Button

@export var targetWindow : Control = null

func _on_button_pressed():
	if targetWindow:
		Launcher.GUI.ToggleControl(targetWindow)
