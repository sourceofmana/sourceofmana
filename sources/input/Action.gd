extends ServiceBase

var isEnabled : bool			= true
var supportMouse : bool			= true
var clickTimer : Timer			= null
var previousMove : Vector2		= Vector2.ZERO
const stickDeadzone : float		= 0.2

var consumed : Dictionary		= {}

#
func Enable(enable : bool):
	isEnabled = enable

func IsEnabled() -> bool:
	return isEnabled

func IsUsable(action : String) -> bool:
	return IsEnabled() and not consumed.has(action)

#
func ConsumeAction(action : String):
	consumed[action] = true

func TryJustPressed(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_pressed(action) and IsActionJustPressed(action, forceMode):
		ConsumeAction(action)
		get_viewport().set_input_as_handled()
		return true
	return false

func TryPressed(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_pressed(action) and IsActionPressed(action, forceMode):
		ConsumeAction(action)
		get_viewport().set_input_as_handled()
		return true
	return false

func TryOnlyPressed(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_pressed(action) and IsActionOnlyPressed(action, forceMode):
		ConsumeAction(action)
		get_viewport().set_input_as_handled()
		return true
	return false

func TryJustReleased(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_released(action) and IsActionJustReleased(action, forceMode):
		ConsumeAction(action)
		get_viewport().set_input_as_handled()
		return true
	return false

#
func IsActionJustPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_just_pressed(action) if IsUsable(action) || forceMode else false

func IsActionPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_pressed(action) if IsUsable(action) || forceMode else false

func IsActionOnlyPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_pressed(action) && not Input.is_action_just_pressed(action) if IsUsable(action) || forceMode else false

func IsActionJustReleased(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_just_released(action) if IsUsable(action) || forceMode else false

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
func _unhandled_input(event):
	if event.is_action("gp_click_to") and supportMouse:
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
func _input(event):
	if TryJustPressed(event, "smile_1"):			Launcher.Network.TriggerEmote(0)
	elif TryJustPressed(event, "smile_2"):			Launcher.Network.TriggerEmote(1)
	elif TryJustPressed(event, "smile_3"):			Launcher.Network.TriggerEmote(2)
	elif TryJustPressed(event, "smile_4"):			Launcher.Network.TriggerEmote(3)
	elif TryJustPressed(event, "smile_5"):			Launcher.Network.TriggerEmote(4)
	elif TryJustPressed(event, "smile_6"):			Launcher.Network.TriggerEmote(5)
	elif TryJustPressed(event, "smile_7"):			Launcher.Network.TriggerEmote(6)
	elif TryJustPressed(event, "smile_8"):			Launcher.Network.TriggerEmote(7)
	elif TryJustPressed(event, "smile_9"):			Launcher.Network.TriggerEmote(8)
	elif TryJustPressed(event, "smile_10"):			Launcher.Network.TriggerEmote(9)
	elif TryJustPressed(event, "smile_11"):			Launcher.Network.TriggerEmote(10)
	elif TryJustPressed(event, "smile_12"):			Launcher.Network.TriggerEmote(11)
	elif TryJustPressed(event, "smile_13"):			Launcher.Network.TriggerEmote(12)
	elif TryJustPressed(event, "smile_14"):			Launcher.Network.TriggerEmote(13)
	elif TryJustPressed(event, "smile_15"):			Launcher.Network.TriggerEmote(14)
	elif TryJustPressed(event, "smile_16"):			Launcher.Network.TriggerEmote(15)
	elif TryJustPressed(event, "smile_17"):			Launcher.Network.TriggerEmote(16)
	elif TryJustPressed(event, "gp_sit"):			Launcher.Network.TriggerSit()
	elif TryJustPressed(event, "gp_target"):		Launcher.Player.Target(Launcher.Player.position)
	elif TryJustPressed(event, "gp_interact"):		Launcher.Player.JustInteract()
	elif TryPressed(event, "gp_interact"):			Launcher.Player.Interact()
	elif TryJustPressed(event, "gp_shortcut_1"):	Launcher.GUI.boxes.Trigger(0)
	elif TryJustPressed(event, "gp_shortcut_2"):	Launcher.GUI.boxes.Trigger(1)
	elif TryJustPressed(event, "gp_shortcut_3"):	Launcher.GUI.boxes.Trigger(2)
	elif TryJustPressed(event, "gp_shortcut_4"):	Launcher.GUI.boxes.Trigger(3)
	elif TryJustPressed(event, "gp_shortcut_5"):	Launcher.GUI.boxes.Trigger(4)
	elif TryJustPressed(event, "gp_shortcut_6"):	Launcher.GUI.boxes.Trigger(5)
	elif TryJustPressed(event, "gp_shortcut_7"):	Launcher.GUI.boxes.Trigger(6)
	elif TryJustPressed(event, "gp_shortcut_8"):	Launcher.GUI.boxes.Trigger(7)
	elif TryJustPressed(event, "gp_shortcut_9"):	Launcher.GUI.boxes.Trigger(8)
	elif TryJustPressed(event, "gp_shortcut_10"):	Launcher.GUI.boxes.Trigger(9)
	elif TryJustPressed(event, "gp_morph"):	 		Launcher.Network.TriggerMorph()
	elif TryJustPressed(event, "ui_close"):			Launcher.GUI.CloseWindow()
	elif TryJustPressed(event, "ui_inventory"):		Launcher.GUI.ToggleControl(Launcher.GUI.inventoryWindow)
	elif TryJustPressed(event, "ui_minimap"):		Launcher.GUI.ToggleControl(Launcher.GUI.minimapWindow)
	elif TryJustPressed(event, "ui_chat"):			Launcher.GUI.ToggleControl(Launcher.GUI.chatWindow)
	elif TryJustPressed(event, "ui_emote"):			Launcher.GUI.ToggleControl(Launcher.GUI.emoteWindow)
	elif TryJustPressed(event, "ui_skill"):			Launcher.GUI.ToggleControl(Launcher.GUI.skillWindow)
	elif TryJustPressed(event, "ui_settings"):		Launcher.GUI.ToggleControl(Launcher.GUI.settingsWindow)
	elif TryJustPressed(event, "ui_stat"):			Launcher.GUI.ToggleControl(Launcher.GUI.statWindow)
	elif TryJustPressed(event, "ui_menu"):			Launcher.GUI.menu._on_button_pressed()
	elif TryJustPressed(event, "ui_validate"):		Launcher.GUI.ToggleChatNewLine()
	elif TryJustPressed(event, "ui_screenshot"):	FileSystem.SaveScreenshot()
	consumed.clear()

#
func _ready():
	clickTimer = Timer.new()
	clickTimer.set_name("ClickTimer")
	clickTimer.set_wait_time(0.2)
	clickTimer.set_one_shot(true)
	add_child(clickTimer)

	DeviceManager.Init()
