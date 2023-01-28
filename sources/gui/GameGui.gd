extends Node

@onready var buttons : Container				= $VBoxMain/HBoxTop/HBoxButtons
@onready var stats : Control					= $VBoxMain/HBoxTop/StatIndicator
@onready var windows : Control					= $FloatingWindows
@onready var boxes : Container					= $VBoxMain/ActionBox
@onready var background : TextureRect			= $Background

@onready var inventoryWindow : InventoryWindow	= $FloatingWindows/Inventory
@onready var emoteWindow : GridContainer		= $FloatingWindows/Emote/ItemContainer/Grid
@onready var chatWindow : Container				= $FloatingWindows/Chat/VBoxContainer

#
func CloseWindow():
	var control : Control = GetCurrentWindow()
	if control && control.has_method("CanBlockActions") && control.CanBlockActions():
		CloseCurrentWindow()
	else:
		ToggleControl($FloatingWindows/Quit)

func GetCurrentWindow() -> Control:
	if windows && windows.get_child_count() > 0:
		return windows.get_child(windows.get_child_count() - 1)
	return null

func CloseCurrentWindow():
	var control : Control = GetCurrentWindow()
	if control:
		ToggleControl(control)

func ToggleControl(control : Control):
	if control:
		control.ToggleControl()

func ToggleChatNewLine(control : Control):
	if control:
		if control.is_visible() == false:
			ToggleControl(control)
		if chatWindow:
			chatWindow.SetNewLineEnabled(!chatWindow.isNewLineEnabled())

#
func EnterLoginMenu():
	for w in buttons.get_children():
		w.set_visible(false)
		if w.targetWindow:
			w.targetWindow.set_visible(false)

	boxes.set_visible(false)
	stats.set_visible(false)
	background.set_visible(true)

func EnterGame():
	if Launcher.Player:
		inventoryWindow.initialize()

		emoteWindow.FillGridContainer(Launcher.DB.EmotesDB)

		background.set_visible(false)

		for w in buttons.get_children():
			w.set_visible(true)
			if w.targetWindow:
				w.targetWindow.set_visible(true)

		boxes.set_visible(true)
		stats.set_visible(true)

#
func _ready():
	Launcher.FSM.enter_login.connect(EnterLoginMenu)
	Launcher.FSM.enter_game.connect(EnterGame)
	get_tree().set_auto_accept_quit(false)

func _process(_delta):
	if Launcher.Action.IsActionJustPressed("ui_close", true): CloseWindow()
	if Launcher.Action.IsActionJustPressed("ui_inventory"): ToggleControl($FloatingWindows/Inventory)
	if Launcher.Action.IsActionJustPressed("ui_minimap"): ToggleControl($FloatingWindows/Minimap)
	if Launcher.Action.IsActionJustPressed("ui_chat"): ToggleControl($FloatingWindows/Chat)
	if Launcher.Action.IsActionJustPressed("ui_chat_newline") : ToggleChatNewLine($FloatingWindows/Chat)
	if Launcher.Action.IsActionJustPressed("ui_screenshot") : Launcher.FileSystem.SaveScreenshot(get_viewport().get_texture().get_image())

func _notification(notif):
	if notif == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		ToggleControl($FloatingWindows/Quit)
	elif notif == Node.NOTIFICATION_WM_MOUSE_EXIT:
		if has_node("FloatingWindows"):
			get_node("FloatingWindows").ClearWindowsModifier()
