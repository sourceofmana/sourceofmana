extends ServiceBase

@onready var background : TextureRect			= $Background

# Overlay
@onready var menu : Control						= $Overlay/Sections/Indicators/Menu
@onready var stats : Control					= $Overlay/Sections/Indicators/Stat

@onready var shortcuts : Container				= $Overlay/Sections/Shortcuts
@onready var sticks : Container					= $Overlay/Sections/Shortcuts/Sticks
@onready var boxes : Control					= $Overlay/Sections/Shortcuts/Boxes

@onready var notificationLabel : RichTextLabel	= $Overlay/Sections/Notification
@onready var dialogueWindow : PanelContainer	= $Overlay/Sections/Contexts/VBox/BottomVbox/Dialogue
@onready var choiceContext : ContextMenu		= $Overlay/Sections/Contexts/VBox/BottomVbox/ChoiceVbox/Choice
@onready var infoContext : ContextMenu			= $Overlay/Sections/Contexts/Info

# Windows
@onready var windows : Control					= $Windows/Floating

@onready var newsWindow : WindowPanel			= $Windows/Floating/News
@onready var loginWindow : WindowPanel			= $Windows/Floating/Login
@onready var inventoryWindow : WindowPanel		= $Windows/Floating/Inventory
@onready var minimapWindow : WindowPanel		= $Windows/Floating/Minimap
@onready var chatWindow : WindowPanel			= $Windows/Floating/Chat
@onready var settingsWindow : WindowPanel		= $Windows/Floating/Settings
@onready var emoteWindow : WindowPanel			= $Windows/Floating/Emote
@onready var skillWindow : WindowPanel			= $Windows/Floating/Skill
@onready var quitWindow : WindowPanel			= $Windows/Floating/Quit
@onready var respawnWindow : WindowPanel		= $Windows/Floating/Respawn
@onready var statWindow : WindowPanel			= $Windows/Floating/Stat

@onready var chatContainer : ChatContainer		= $Windows/Floating/Chat/Margin/VBoxContainer
@onready var emoteContainer : Container			= $Windows/Floating/Emote/ItemContainer/Grid

# Shaders
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
		chatContainer.SetNewLineEnabled(true)

#
func EnterLoginMenu():
	infoContext.set_visible(false)

	menu.SetItemsVisible(false)
	stats.set_visible(false)
	statWindow.set_visible(false)

	dialogueWindow.set_visible(false)
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
		infoContext.Clear()
		infoContext.Push(ContextData.new("gp_interact"))
		infoContext.Push(ContextData.new("gp_untarget"))
		infoContext.Push(ContextData.new("gp_morph"))
		infoContext.Push(ContextData.new("gp_sit"))
		infoContext.FadeIn()

		background.set_visible(false)
		loginWindow.EnableControl(false)
		newsWindow.EnableControl(false)

		stats.set_visible(true)
		menu.set_visible(true)
		shortcuts.set_visible(true)
		notificationLabel.set_visible(true)

		menu.SetItemsVisible(true)
		stats.Init()
		statWindow.Init(Launcher.Player)

#
func _post_launch():
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

	if Launcher.FSM:
		Launcher.FSM.enter_login.connect(EnterLoginMenu)
		Launcher.FSM.enter_game.connect(EnterGame)

	isInitialized = true

func _notification(notif):
	match notif:
		Node.NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			ToggleControl(quitWindow)
		Node.NOTIFICATION_WM_MOUSE_EXIT:
			if windows:
				windows.ClearWindowsModifier()
		Node.NOTIFICATION_DRAG_BEGIN:
			Launcher.Action.Enable(false)
		Node.NOTIFICATION_DRAG_END:
			Launcher.Action.Enable(true)

func _ready():
	Util.Assert(CRTShader.material != null, "CRT Shader can't load as its texture material is missing")
	CRTShader.material.set_shader_parameter("resolution", get_viewport().size / 2)

func _on_ui_margin_resized():
	if CRTShader and CRTShader.material:
		CRTShader.material.set_shader_parameter("resolution", get_viewport().size / 2)

	if settingsWindow:
		settingsWindow.set_fullscreen(DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN)
		settingsWindow.set_windowPos(DisplayServer.window_get_position(0))
		settingsWindow.set_resolution(DisplayServer.window_get_size(0))
