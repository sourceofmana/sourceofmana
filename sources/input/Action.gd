extends ServiceBase

var isEnabled : bool			= true
var supportMouse : bool			= true
var clickTimer : Timer			= null
var previousMove : Vector2		= Vector2.ZERO
const stickDeadzone : float		= 0.2

#
func Enable(enable : bool):
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
		moveVector += Launcher.GUI.sticks.GetMove()
		moveVector = moveVector.normalized()

		var moveLength : float = moveVector.length()
		if moveLength < stickDeadzone:
			moveVector = Vector2.ZERO;
		else:
			moveVector = moveVector.normalized() * ((moveLength - stickDeadzone) / (1 - stickDeadzone))

	return moveVector

# Local player movement
func _unhandled_input(_event):
	if not supportMouse:
		return

	if get_viewport() and Launcher.Camera and Launcher.Camera.mainCamera and clickTimer:
		if clickTimer.is_stopped() and IsActionPressed("gp_click_to"):
			var mousePos : Vector2 = Launcher.Camera.mainCamera.get_global_mouse_position()
			Launcher.Network.SetClickPos(mousePos)
			clickTimer.start()

func _physics_process(_deltaTime : float):
	if Launcher.Player:
		var move : Vector2 = GetMove()
		if move != Vector2.ZERO:
			if clickTimer.get_time_left() > 0:
				clickTimer.stop()
			if previousMove != move:
				Launcher.Network.SetMovePos(move)
		else:
			if previousMove != move:
				Launcher.Player.entityVelocity = move
				Launcher.Network.ClearNavigation()
		previousMove = move

#
		if IsActionJustPressed("smile_1"):			Launcher.Network.TriggerEmote(0)
		elif IsActionJustPressed("smile_2"):		Launcher.Network.TriggerEmote(1)
		elif IsActionJustPressed("smile_3"):		Launcher.Network.TriggerEmote(2)
		elif IsActionJustPressed("smile_4"):		Launcher.Network.TriggerEmote(3)
		elif IsActionJustPressed("smile_5"):		Launcher.Network.TriggerEmote(4)
		elif IsActionJustPressed("smile_6"):		Launcher.Network.TriggerEmote(5)
		elif IsActionJustPressed("smile_7"):		Launcher.Network.TriggerEmote(6)
		elif IsActionJustPressed("smile_8"):		Launcher.Network.TriggerEmote(7)
		elif IsActionJustPressed("smile_9"):		Launcher.Network.TriggerEmote(8)
		elif IsActionJustPressed("smile_10"):		Launcher.Network.TriggerEmote(9)
		elif IsActionJustPressed("smile_11"):		Launcher.Network.TriggerEmote(10)
		elif IsActionJustPressed("smile_12"):		Launcher.Network.TriggerEmote(11)
		elif IsActionJustPressed("smile_13"):		Launcher.Network.TriggerEmote(12)
		elif IsActionJustPressed("smile_14"):		Launcher.Network.TriggerEmote(13)
		elif IsActionJustPressed("smile_15"):		Launcher.Network.TriggerEmote(14)
		elif IsActionJustPressed("smile_16"):		Launcher.Network.TriggerEmote(15)
		elif IsActionJustPressed("smile_17"):		Launcher.Network.TriggerEmote(16)
		elif IsActionJustPressed("gp_sit"):			Launcher.Network.TriggerSit()
		elif IsActionJustPressed("gp_target"):		Launcher.Player.Target(Launcher.Player.position)
		elif IsActionPressed("gp_interact"):		Launcher.Player.Interact()
		elif IsActionJustPressed("gp_shortcut_1"):	 Launcher.GUI.boxes.Trigger(0)
		elif IsActionJustPressed("gp_shortcut_2"):	 Launcher.GUI.boxes.Trigger(1)
		elif IsActionJustPressed("gp_shortcut_3"):	 Launcher.GUI.boxes.Trigger(2)
		elif IsActionJustPressed("gp_shortcut_4"):	 Launcher.GUI.boxes.Trigger(3)
		elif IsActionJustPressed("gp_shortcut_5"):	 Launcher.GUI.boxes.Trigger(4)
		elif IsActionJustPressed("gp_shortcut_6"):	 Launcher.GUI.boxes.Trigger(5)
		elif IsActionJustPressed("gp_shortcut_7"):	 Launcher.GUI.boxes.Trigger(6)
		elif IsActionJustPressed("gp_shortcut_8"):	 Launcher.GUI.boxes.Trigger(7)
		elif IsActionJustPressed("gp_shortcut_9"):	 Launcher.GUI.boxes.Trigger(8)
		elif IsActionJustPressed("gp_shortcut_10"):	 Launcher.GUI.boxes.Trigger(9)
		elif IsActionJustPressed("gp_morph"):	 	Launcher.Network.TriggerMorph()
		elif IsActionJustPressed("ui_close", true):	Launcher.GUI.CloseWindow()
		elif IsActionJustPressed("ui_inventory"):	Launcher.GUI.ToggleControl(Launcher.GUI.inventoryWindow)
		elif IsActionJustPressed("ui_minimap"):		Launcher.GUI.ToggleControl(Launcher.GUI.minimapWindow)
		elif IsActionJustPressed("ui_chat"):		Launcher.GUI.ToggleControl(Launcher.GUI.chatWindow)
		elif IsActionJustPressed("ui_emote"):		Launcher.GUI.ToggleControl(Launcher.GUI.emoteWindow)
		elif IsActionJustPressed("ui_skill"):		Launcher.GUI.ToggleControl(Launcher.GUI.skillWindow)
		elif IsActionJustPressed("ui_settings"):	Launcher.GUI.ToggleControl(Launcher.GUI.settingsWindow)
		elif IsActionJustPressed("ui_stat"):		Launcher.GUI.ToggleControl(Launcher.GUI.statWindow)
		elif IsActionJustPressed("ui_menu"):		Launcher.GUI.menu._on_button_pressed()
		elif IsActionJustPressed("ui_validate"):	Launcher.GUI.ToggleChatNewLine()
		elif IsActionJustPressed("ui_screenshot"):	FileSystem.SaveScreenshot()

#
func _ready():
	clickTimer = Timer.new()
	clickTimer.set_name("ClickTimer")
	clickTimer.set_wait_time(0.2)
	clickTimer.set_one_shot(true)
	add_child(clickTimer)

	DeviceManager.Init()
