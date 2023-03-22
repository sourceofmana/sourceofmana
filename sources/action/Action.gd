extends Node

var isEnabled : bool = true

#
func Enable(enable : bool):
	# Force one full loop to change the state
	await Launcher.get_tree().process_frame
	await Launcher.get_tree().process_frame
	isEnabled = enable

func IsEnabled() -> bool:
	return isEnabled

#
func IsActionJustPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_just_pressed(action) if IsEnabled() || forceMode else false

func IsActionPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_pressed(action) if IsEnabled() || forceMode else false

func IsActionOnlyPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_pressed(action) && not Input.is_action_just_pressed(action) if IsEnabled() || forceMode else false

func IsActionJustReleased(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_just_released(action) if IsEnabled() || forceMode else false

func GetMove(forceMode : bool = false) -> Vector2:
	var moveVector : Vector2 = Vector2.ZERO
	if IsEnabled() || forceMode:
		moveVector.x = Input.get_action_strength("gp_move_right") - Input.get_action_strength("gp_move_left")
		moveVector.y = Input.get_action_strength("gp_move_down") - Input.get_action_strength("gp_move_up")
		moveVector.normalized()
	return moveVector

# Local player movement
func _unhandled_input(_event):
	if Launcher.Player && Launcher.Player.timer:
		var timer : Timer = Launcher.Player.timer
		if timer.is_stopped() and IsActionPressed("gp_click_to"):
			var mousePos : Vector2 = Launcher.Camera.mainCamera.get_global_mouse_position()
			Launcher.Network.SetClickPos(mousePos)
			timer.start()

func _physics_process(_deltaTime : float):
	if Launcher.Player && Launcher.Player.timer:
		var timer : Timer = Launcher.Player.timer
		if not IsActionPressed("gp_click_to"):
			var movePos : Vector2 = GetMove()
			if movePos != Vector2.ZERO:
				if timer.get_time_left() > 0:
					timer.stop()
				Launcher.Network.SetMovePos(movePos)
#
		if Launcher.Action.IsActionJustPressed("gp_sit"):		Launcher.Network.TriggerSit()
#
		if Launcher.Action.IsActionJustPressed("smile_1"):		Launcher.Network.TriggerEmote(1)
		elif Launcher.Action.IsActionJustPressed("smile_2"):	Launcher.Network.TriggerEmote(2)
		elif Launcher.Action.IsActionJustPressed("smile_3"):	Launcher.Network.TriggerEmote(3)
		elif Launcher.Action.IsActionJustPressed("smile_4"):	Launcher.Network.TriggerEmote(4)
		elif Launcher.Action.IsActionJustPressed("smile_5"):	Launcher.Network.TriggerEmote(5)
		elif Launcher.Action.IsActionJustPressed("smile_6"):	Launcher.Network.TriggerEmote(6)
		elif Launcher.Action.IsActionJustPressed("smile_7"):	Launcher.Network.TriggerEmote(7)
		elif Launcher.Action.IsActionJustPressed("smile_8"):	Launcher.Network.TriggerEmote(8)
		elif Launcher.Action.IsActionJustPressed("smile_9"):	Launcher.Network.TriggerEmote(9)
		elif Launcher.Action.IsActionJustPressed("smile_10"):	Launcher.Network.TriggerEmote(10)
		elif Launcher.Action.IsActionJustPressed("smile_11"):	Launcher.Network.TriggerEmote(11)
		elif Launcher.Action.IsActionJustPressed("smile_12"):	Launcher.Network.TriggerEmote(12)
		elif Launcher.Action.IsActionJustPressed("smile_13"):	Launcher.Network.TriggerEmote(13)
		elif Launcher.Action.IsActionJustPressed("smile_14"):	Launcher.Network.TriggerEmote(14)
		elif Launcher.Action.IsActionJustPressed("smile_15"):	Launcher.Network.TriggerEmote(15)
		elif Launcher.Action.IsActionJustPressed("smile_16"):	Launcher.Network.TriggerEmote(16)
		elif Launcher.Action.IsActionJustPressed("smile_17"):	Launcher.Network.TriggerEmote(17)
