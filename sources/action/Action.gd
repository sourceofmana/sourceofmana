extends Node

var isEnabled : bool			= true
var clickTimer : Timer			= null

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
	if Launcher.Camera and clickTimer:
		if clickTimer.is_stopped() and IsActionPressed("gp_click_to"):
			var mousePos : Vector2 = Launcher.Camera.mainCamera.get_global_mouse_position()
			Launcher.Network.SetClickPos(mousePos)
			clickTimer.start()

func _physics_process(_deltaTime : float):
	if Launcher.Player and Launcher.Network:
		if clickTimer and not IsActionPressed("gp_click_to"):
			var movePos : Vector2 = GetMove()
			if movePos != Vector2.ZERO:
				if clickTimer.get_time_left() > 0:
					clickTimer.stop()
				Launcher.Network.SetMovePos(movePos)
#
		if IsActionJustPressed("gp_sit"):			Launcher.Network.TriggerSit()
		elif IsActionJustPressed("gp_interact"):	 Launcher.Player.Interact()
		elif IsActionJustPressed("smile_1"):		Launcher.Network.TriggerEmote(1)
		elif IsActionJustPressed("smile_2"):		Launcher.Network.TriggerEmote(2)
		elif IsActionJustPressed("smile_3"):		Launcher.Network.TriggerEmote(3)
		elif IsActionJustPressed("smile_4"):		Launcher.Network.TriggerEmote(4)
		elif IsActionJustPressed("smile_5"):		Launcher.Network.TriggerEmote(5)
		elif IsActionJustPressed("smile_6"):		Launcher.Network.TriggerEmote(6)
		elif IsActionJustPressed("smile_7"):		Launcher.Network.TriggerEmote(7)
		elif IsActionJustPressed("smile_8"):		Launcher.Network.TriggerEmote(8)
		elif IsActionJustPressed("smile_9"):		Launcher.Network.TriggerEmote(9)
		elif IsActionJustPressed("smile_10"):		Launcher.Network.TriggerEmote(10)
		elif IsActionJustPressed("smile_11"):		Launcher.Network.TriggerEmote(11)
		elif IsActionJustPressed("smile_12"):		Launcher.Network.TriggerEmote(12)
		elif IsActionJustPressed("smile_13"):		Launcher.Network.TriggerEmote(13)
		elif IsActionJustPressed("smile_14"):		Launcher.Network.TriggerEmote(14)
		elif IsActionJustPressed("smile_15"):		Launcher.Network.TriggerEmote(15)
		elif IsActionJustPressed("smile_16"):		Launcher.Network.TriggerEmote(16)
		elif IsActionJustPressed("smile_17"):		Launcher.Network.TriggerEmote(17)
		elif IsActionJustPressed("ui_close", true):	Launcher.GUI.CloseWindow()
		elif IsActionJustPressed("ui_inventory"):	Launcher.GUI.ToggleControl(Launcher.GUI.inventoryWindow)
		elif IsActionJustPressed("ui_minimap"):		Launcher.GUI.ToggleControl(Launcher.GUI.minimapWindow)
		elif IsActionJustPressed("ui_chat"):		Launcher.GUI.ToggleControl(Launcher.GUI.chatWindow)
		elif IsActionJustPressed("ui_emote"):		Launcher.GUI.ToggleControl(Launcher.GUI.emoteWindow)
		elif IsActionJustPressed("ui_validate"):	Launcher.GUI.ToggleChatNewLine(Launcher.GUI.chatWindow)
		elif IsActionJustPressed("ui_screenshot"):	Launcher.FileSystem.SaveScreenshot(Launcher.Util.GetScreenCapture())

#
func _ready():
	clickTimer = Timer.new()
	clickTimer.set_name("ClickTimer")
	clickTimer.set_wait_time(0.2)
	clickTimer.set_one_shot(true)
	add_child(clickTimer)
