extends ServiceBase

var disableCounter : int		= 0
var isEnabled : bool			= true
var supportMouse : bool			= true
var clickTimer : Timer			= null
var previousMove : Vector2		= Vector2.ZERO
const stickDeadzone : float		= 0.2

var consumed : Array[String]	= []

signal deviceChanged

#
func Enable(enable : bool):
	if enable:
		pass
	disableCounter = clampi(disableCounter + (1 if enable else -1), -256, 0)
	isEnabled = disableCounter == 0

func IsEnabled() -> bool:
	return isEnabled

func IsUsable(action : String) -> bool:
	return IsEnabled() and not consumed.has(action)

#
func HasConsumed() -> bool:
	return not consumed.is_empty()

func ConsumeAction(action : String, setHandled : bool = false):
	consumed.push_back(action)
	if setHandled:
		get_viewport().set_input_as_handled()

func TryConsume(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_pressed(action, false, true) and Launcher.Action.IsActionPressed(action, forceMode):
		ConsumeAction(action)
		return true
	return false

func TryJustPressed(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_pressed(action, false, true) and IsActionJustPressed(action, forceMode):
		ConsumeAction(action, true)
		return true
	return false

func TryPressed(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_pressed(action, true, true) and IsActionPressed(action, forceMode):
		ConsumeAction(action, true)
		return true
	return false

func TryOnlyPressed(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_pressed(action, true, true) and IsActionOnlyPressed(action, forceMode):
		ConsumeAction(action, true)
		return true
	return false

func TryJustReleased(event : InputEvent, action : String, forceMode : bool = false) -> bool:
	if event.is_action_released(action) and IsActionJustReleased(action, forceMode):
		ConsumeAction(action, true)
		return true
	return false

#
func IsActionJustPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_just_pressed(action) if forceMode or IsUsable(action) else false

func IsActionPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_pressed(action) if forceMode or IsUsable(action) else false

func IsActionOnlyPressed(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_pressed(action) && not Input.is_action_just_pressed(action) if forceMode or IsUsable(action) else false

func IsActionJustReleased(action : String, forceMode : bool = false) -> bool:
	return Input.is_action_just_released(action) if forceMode or IsEnabled() else false

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
func MoveTo(pos : Vector2):
	Network.SetClickPos(pos)
	clickTimer.start()

func _unhandled_input(event):
	if event.is_action("gp_click_to") and supportMouse:
		if FSM.IsGameState() and clickTimer:
			if clickTimer.is_stopped() and IsActionPressed("gp_click_to"):
				MoveTo(Launcher.Camera.mainCamera.get_global_mouse_position())
	elif not HasConsumed() and Launcher.Camera:
		if event is InputEventMagnifyGesture:
			if event.factor > 1.0:
				ConsumeAction("gp_zoom_in", true)
				Launcher.Camera.ZoomIn()
			elif event.factor < 1.0:
				ConsumeAction("gp_zoom_out", true)
				Launcher.Camera.ZoomOut()
		elif TryJustPressed(event, "gp_zoom_in"):		Launcher.Camera.ZoomIn()
		elif TryJustPressed(event, "gp_zoom_out"):		Launcher.Camera.ZoomOut()
		elif TryJustPressed(event, "gp_zoom_reset"):	Launcher.Camera.ZoomReset()

func _physics_process(_deltaTime : float):
	if Launcher.Player:
		var move : Vector2 = GetMove()
		if move != Vector2.ZERO:
			if clickTimer.get_time_left() > 0:
				clickTimer.stop()
			if previousMove != move:
				Network.SetMovePos(move)
		else:
			if previousMove != move:
				Network.ClearNavigation()
		previousMove = move

#
func _input(event : InputEvent):
	if event.is_pressed():
		if event is InputEventJoypadButton and DeviceManager.currentDeviceType != DeviceManager.DeviceType.JOYSTICK:
			DeviceManager.DeviceChanged(DeviceManager.DeviceType.JOYSTICK)
		elif event is InputEventKey and DeviceManager.currentDeviceType != DeviceManager.DeviceType.KEYBOARD:
			DeviceManager.DeviceChanged(DeviceManager.DeviceType.KEYBOARD)
	if Launcher.Player and Launcher.GUI and Launcher.Map:
		if TryJustPressed(event, "smile_1"):			Network.TriggerEmote(DB.GetCellHash("Dying"))
		elif TryJustPressed(event, "smile_2"):			Network.TriggerEmote(DB.GetCellHash("Creeped"))
		elif TryJustPressed(event, "smile_3"):			Network.TriggerEmote(DB.GetCellHash("Smile"))
		elif TryJustPressed(event, "smile_4"):			Network.TriggerEmote(DB.GetCellHash("Sad"))
		elif TryJustPressed(event, "smile_5"):			Network.TriggerEmote(DB.GetCellHash("Evil"))
		elif TryJustPressed(event, "smile_6"):			Network.TriggerEmote(DB.GetCellHash("Wink"))
		elif TryJustPressed(event, "smile_7"):			Network.TriggerEmote(DB.GetCellHash("Angel"))
		elif TryJustPressed(event, "smile_8"):			Network.TriggerEmote(DB.GetCellHash("Embarrassed"))
		elif TryJustPressed(event, "smile_9"):			Network.TriggerEmote(DB.GetCellHash("Amused"))
		elif TryJustPressed(event, "smile_10"):			Network.TriggerEmote(DB.GetCellHash("Grin"))
		elif TryJustPressed(event, "smile_11"):			Network.TriggerEmote(DB.GetCellHash("Angry"))
		elif TryJustPressed(event, "smile_12"):			Network.TriggerEmote(DB.GetCellHash("Bored"))
		elif TryJustPressed(event, "smile_13"):			Network.TriggerEmote(DB.GetCellHash("Bubble"))
		elif TryJustPressed(event, "smile_14"):			Network.TriggerEmote(DB.GetCellHash("Dots"))
		elif TryJustPressed(event, "smile_15"):			Network.TriggerEmote(DB.GetCellHash("Whatever"))
		elif TryJustPressed(event, "smile_16"):			Network.TriggerEmote(DB.GetCellHash("Surprised"))
		elif TryJustPressed(event, "smile_17"):			Network.TriggerEmote(DB.GetCellHash("Confused"))
		elif TryJustPressed(event, "gp_sit"):			Network.TriggerSit()
		elif TryJustPressed(event, "gp_target"):		Launcher.Player.Target(Launcher.Player.position, true, true)
		elif TryJustPressed(event, "gp_untarget"):		Launcher.Player.ClearTarget()
		elif TryJustPressed(event, "gp_interact"):		Launcher.Player.JustInteract()
		elif TryPressed(event, "gp_interact"):			Launcher.Player.Interact()
		elif TryJustPressed(event, "gp_pickup"):		Launcher.Map.PickupNearestDrop()
		elif TryJustPressed(event, "gp_morph"):			Network.TriggerMorph()
		elif TryJustPressed(event, "gp_run"):			Network.TriggerRun(true)
		elif TryJustReleased(event, "gp_run"):			Network.TriggerRun(false)
	if not HasConsumed() and Launcher.GUI:
		if TryJustPressed(event, "ui_close"):			Launcher.GUI.CloseWindow()
		elif TryJustPressed(event, "ui_close", true):	Launcher.GUI.CloseCurrent()
		elif TryJustPressed(event, "ui_menu"):			Launcher.GUI.menu._on_button_pressed()
		elif FSM.IsGameState():
			if TryJustPressed(event, "ui_inventory"):		Launcher.GUI.ToggleControl(Launcher.GUI.inventoryWindow)
			elif TryJustPressed(event, "ui_minimap"):		Launcher.GUI.ToggleControl(Launcher.GUI.minimapWindow)
			elif TryJustPressed(event, "ui_chat"):			Launcher.GUI.ToggleControl(Launcher.GUI.chatWindow)
			elif TryJustPressed(event, "ui_emote"):			Launcher.GUI.ToggleControl(Launcher.GUI.emoteWindow)
			elif TryJustPressed(event, "ui_skill"):			Launcher.GUI.ToggleControl(Launcher.GUI.skillWindow)
			elif TryJustPressed(event, "ui_settings"):		Launcher.GUI.ToggleControl(Launcher.GUI.settingsWindow)
			elif TryJustPressed(event, "ui_stat"):			Launcher.GUI.ToggleControl(Launcher.GUI.statWindow)
			elif TryJustPressed(event, "ui_validate"):		Launcher.GUI.ToggleChatNewLine()
			elif TryJustPressed(event, "ui_screenshot"):	FileSystem.SaveScreenshot()
			elif TryJustPressed(event, "ui_fullscreen"):	Launcher.GUI.ToggleFullscreen()
	consumed.clear()

#
func _ready():
	clickTimer = Timer.new()
	clickTimer.set_name("ClickTimer")
	clickTimer.set_wait_time(0.2)
	clickTimer.set_one_shot(true)
	add_child.call_deferred(clickTimer)

	DeviceManager.Init()

func Destroy():
	if clickTimer:
		remove_child.call_deferred(clickTimer)
		clickTimer.queue_free()
		clickTimer = null
