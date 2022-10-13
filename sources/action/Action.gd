extends Node

var isEnabled : bool = true

#
func Enable(enable : bool):
	await Launcher.get_tree().process_frame
	isEnabled = enable

func IsEnabled() -> bool:
	return isEnabled

#
func IsActionJustPressed(action : String, forceMode : bool = false) -> bool:
	var state : bool = Input.is_action_just_pressed(action)
	return state if IsEnabled() || forceMode else false

func IsActionPressed(action : String, forceMode : bool = false) -> bool:
	var state : bool = Input.is_action_just_pressed(action)
	return state if IsEnabled() || forceMode else false
