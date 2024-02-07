extends ServiceBase

@onready var menu : Control						= $UIMargin/UIOverlay/Indicators/Menu
@onready var stats : Control					= $UIMargin/UIOverlay/Indicators/Stat
@onready var shortcuts : Container				= $UIMargin/UIOverlay/Shortcuts

@onready var boxes : Container					= $UIMargin/UIOverlay/Shortcuts/Boxes
@onready var sticks : Container					= $UIMargin/UIOverlay/Shortcuts/Sticks

@onready var background : TextureRect			= $Background

@onready var windows : Control					= $FloatingWindows
@onready var newsWindow : WindowPanel			= $FloatingWindows/News
@onready var loginWindow : WindowPanel			= $FloatingWindows/Login
@onready var inventoryWindow : WindowPanel		= $FloatingWindows/Inventory
@onready var minimapWindow : WindowPanel		= $FloatingWindows/Minimap
@onready var chatWindow : WindowPanel			= $FloatingWindows/Chat
@onready var settingsWindow : WindowPanel		= $FloatingWindows/Settings
@onready var emoteWindow : WindowPanel			= $FloatingWindows/Emote
@onready var quitWindow : WindowPanel			= $FloatingWindows/Quit
@onready var respawnWindow : WindowPanel		= $FloatingWindows/RespawnWindow

@onready var chatContainer : ChatContainer		= $FloatingWindows/Chat/Margin/VBoxContainer
@onready var emoteContainer : Container			= $FloatingWindows/Emote/ItemContainer/Grid

@onready var notificationLabel : RichTextLabel	= $UIMargin/UIOverlay/Notification

@onready var CRTShader : TextureRect			= $Shaders/CRT
@onready var HQ4xShader : TextureRect			= $Shaders/HQ4x

#
func CloseWindow():
	ToggleControl(quitWindow)

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

func ToggleChatNewLine():
	if chatWindow:
		if chatWindow.is_visible() == false:
			ToggleControl(chatWindow)
		if chatContainer:
			chatContainer.SetNewLineEnabled(!chatContainer.isNewLineEnabled())

#
func EnterLoginMenu():
	menu.SetItemsVisible(false)

	stats.set_visible(false)
	notificationLabel.set_visible(false)
	menu.set_visible(false)
	shortcuts.set_visible(false)
	quitWindow.set_visible(false)
	respawnWindow.EnableControl(false)

	background.set_visible(true)
	newsWindow.EnableControl(true)
	loginWindow.EnableControl(true)

func EnterGame():
	if Launcher.Player:
		inventoryWindow.initialize()
		emoteContainer.FillGridContainer(Launcher.DB.EmotesDB)

		background.set_visible(false)
		loginWindow.EnableControl(false)
		newsWindow.EnableControl(false)

		stats.set_visible(true)
		menu.set_visible(true)
		shortcuts.set_visible(true)
		notificationLabel.set_visible(true)

		menu.SetItemsVisible(true)

#
func _post_launch():
	if Launcher.FSM and not Launcher.FSM.enter_login.is_connected(EnterLoginMenu):
		Launcher.FSM.enter_login.connect(EnterLoginMenu)
	if Launcher.FSM and not Launcher.FSM.enter_game.is_connected(EnterGame):
		Launcher.FSM.enter_game.connect(EnterGame)
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

	isInitialized = true

func _notification(notif):
	match notif:
		Node.NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			ToggleControl(quitWindow)
		Node.NOTIFICATION_WM_MOUSE_EXIT:
			if has_node("FloatingWindows"):
				get_node("FloatingWindows").ClearWindowsModifier()

func _ready():
	Util.Assert(CRTShader.material != null, "CRT Shader can't load as its texture material is missing")
	CRTShader.material.set_shader_parameter("resolution", get_viewport().size / 2)

func _on_ui_margin_resized():
	if CRTShader and CRTShader.material:
		CRTShader.material.set_shader_parameter("resolution", get_viewport().size / 2)
