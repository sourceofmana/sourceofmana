extends Node

@onready var buttons : Container				= $VBoxMain/HBoxTop/HBoxButtons
@onready var stats : Control					= $VBoxMain/HBoxTop/StatIndicator
@onready var windows : Control					= $FloatingWindows
@onready var boxes : Container					= $VBoxMain/ActionBox
@onready var background : TextureRect			= $Background

@onready var modeWindow : WindowPanel			= $FloatingWindows/Mode
@onready var welcomeWindow : WindowPanel		= $FloatingWindows/Welcome
@onready var loginWindow : WindowPanel			= $FloatingWindows/Login
@onready var inventoryWindow : WindowPanel		= $FloatingWindows/Inventory
@onready var minimapWindow : WindowPanel		= $FloatingWindows/Minimap
@onready var chatWindow : WindowPanel			= $FloatingWindows/Chat
@onready var emoteWindow : WindowPanel			= $FloatingWindows/Emote

@onready var chatContainer : ChatContainer		= $FloatingWindows/Chat/VBoxContainer
@onready var emoteContainer : Container			= $FloatingWindows/Emote/ItemContainer/Grid

#
func CloseWindow():
	ToggleControl($FloatingWindows/Quit)

func GetCurrentWindow() -> Control:
	if windows && windows.get_child_count() > 0:
		return windows.get_child(windows.get_child_count() - 1)
	return null

func CloseCurrentWindow():
	var control : WindowPanel = GetCurrentWindow()
	if control:
		ToggleControl(control)

func ToggleControl(control : WindowPanel):
	if control:
		control.ToggleControl()

func ToggleChatNewLine(control : WindowPanel):
	if control:
		if control.is_visible() == false:
			ToggleControl(control)
		if chatContainer:
			chatContainer.SetNewLineEnabled(!chatContainer.isNewLineEnabled())

#
func EnterLoginMenu():
	for w in buttons.get_children():
		w.set_visible(false)
		if w.targetWindow:
			w.targetWindow.EnableControl(false)

	buttons.set_visible(true)
	boxes.set_visible(false)
	stats.set_visible(false)
	background.set_visible(true)

	modeWindow.EnableControl(false)
	welcomeWindow.EnableControl(true)
	loginWindow.EnableControl(true)

func EnterGame():
	if Launcher.Player:
		modeWindow.EnableControl(false)
		inventoryWindow.initialize()
		emoteContainer.FillGridContainer(Launcher.DB.EmotesDB)

		background.set_visible(false)
		boxes.set_visible(true)
		stats.set_visible(true)

		for w in buttons.get_children():
			w.set_visible(true)
			if w.targetWindow:
				w.targetWindow.EnableControl(true)

		loginWindow.EnableControl(false)
		welcomeWindow.EnableControl(false)

#
func _post_launch():
	if Launcher.Map and not Launcher.FSM.enter_login.is_connected(EnterLoginMenu):
		Launcher.FSM.enter_login.connect(EnterLoginMenu)
	if Launcher.Map and not Launcher.FSM.enter_game.is_connected(EnterGame):
		Launcher.FSM.enter_game.connect(EnterGame)
	get_tree().set_auto_accept_quit(false)

func _notification(notif):
	if notif == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		ToggleControl($FloatingWindows/Quit)
	elif notif == Node.NOTIFICATION_WM_MOUSE_EXIT:
		if has_node("FloatingWindows"):
			get_node("FloatingWindows").ClearWindowsModifier()
