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
func _process(deltaTime : float):
	if Launcher.Player && Launcher.Player.timer:
		var timer : Timer = Launcher.Player.timer
		if timer.is_stopped() and IsActionPressed("gp_click_to"):
			var mousePos : Vector2 = Launcher.Camera.mainCamera.get_global_mouse_position()
			Launcher.Network.Client.SetClickPos(mousePos)
			timer.start()
		else:
			var movePos : Vector2 = GetMove()
			if movePos != Vector2.ZERO:
				if timer.get_time_left() > 0:
					timer.stop()
				Launcher.Network.Client.SetMovePos(movePos, deltaTime)
