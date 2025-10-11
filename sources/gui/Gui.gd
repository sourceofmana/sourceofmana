extends ServiceBase

@onready var background : TextureRect			= $Background

# Overlay
@onready var menu : Control						= $Overlay/VSections/Indicators/Menu
@onready var stats : Control					= $Overlay/VSections/Indicators/Stat
@onready var notificationLabel : RichTextLabel	= $Overlay/VSections/Indicators/Info/Notification
@onready var pickupPanel : PanelContainer		= $Overlay/VSections/Indicators/Info/PickUp

# Contexts
@onready var loadingControl : Control			= $Overlay/VSections/Contexts/Loading
@onready var dialogueWindow : VBoxContainer		= $Overlay/VSections/Contexts/Dialogue
@onready var dialogueContainer : PanelContainer	= $Overlay/VSections/Contexts/Dialogue/BottomVbox/Dialogue
@onready var choiceContext : ContextMenu		= $Overlay/VSections/Contexts/Dialogue/BottomVbox/ChoiceVbox/Choice
@onready var infoContext : ContextMenu			= $Overlay/VSections/Contexts/Info
@onready var messageBox : Control				= $Overlay/VSections/Contexts/MessageBox
@onready var loginPanel : Control				= $Overlay/VSections/Contexts/Login
@onready var characterPanel : Control			= $Overlay/VSections/Contexts/Character

# Shortcuts
@onready var actionBoxes : Control				= $Overlay/VSections/ButtonBar/ActionBoxes
@onready var buttonBoxes : Control				= $Overlay/VSections/ButtonBar/ButtonBoxes
@onready var shortcuts : Container				= $Overlay/Sections/Shortcuts
@onready var sticks : Container					= $Overlay/Sections/Shortcuts/Sticks

# Windows
@onready var windows : Control					= $Windows/Floating
@onready var inventoryWindow : WindowPanel		= $Windows/Floating/Inventory
@onready var minimapWindow : WindowPanel		= $Windows/Floating/Minimap
@onready var chatWindow : WindowPanel			= $Windows/Floating/Chat
@onready var settingsWindow : WindowPanel		= $Windows/Floating/Settings
@onready var emoteWindow : WindowPanel			= $Windows/Floating/Emote
@onready var skillWindow : WindowPanel			= $Windows/Floating/Skill
@onready var progressWindow : WindowPanel		= $Windows/Floating/Progress
@onready var quitWindow : WindowPanel			= $Windows/Floating/Quit
@onready var respawnWindow : WindowPanel		= $Windows/Floating/Respawn
@onready var statWindow : WindowPanel			= $Windows/Floating/Stat

@onready var chatContainer : ChatContainer		= $Windows/Floating/Chat/Margin/VBoxContainer
@onready var emoteContainer : Container			= $Windows/Floating/Emote/ItemContainer/Grid

# Shaders
@onready var CRTShader : TextureRect			= $Shaders/CRT
@onready var HQ4xShader : TextureRect			= $Shaders/HQ4x

# State transition
var progressTimer : Timer						= null

#
func CloseWindow():
	if FSM.IsLoginState():
		loginPanel.Close()
	elif FSM.IsCharacterState():
		characterPanel.Close()
	elif FSM.IsGameState():
		ToggleControl(quitWindow)

func GetCurrentWindow() -> Control:
	if windows && windows.get_child_count() > 0:
		return windows.get_child(windows.get_child_count() - 1)
	return null

func CloseCurrent():
	var focusedNode : Control = get_viewport().gui_get_focus_owner()
	if focusedNode and focusedNode is LineEdit:
		focusedNode.release_focus()
	else:
		var control : WindowPanel = GetCurrentWindow()
		if control and control.is_visible():
			ToggleControl(control)

func ToggleControl(control : WindowPanel):
	if control:
		control.ToggleControl()

func ToggleChatNewLine():
	if chatWindow:
		if chatWindow.is_visible() == false:
			ToggleControl(chatWindow)
		chatContainer.SetNewLineEnabled(true)

func ToggleFullscreen():
	if settingsWindow:
		settingsWindow.set_fullscreen(!settingsWindow.is_fullscreen())

func DisplayInfoContext(actions : PackedStringArray):
	infoContext.Clear()
	for action in actions:
		if DeviceManager.HasActionName(action):
			infoContext.Push(ContextData.new(action))
	infoContext.FadeIn()

func IsDialogueContextOpened() -> bool:
	return Launcher.GUI.dialogueContainer.is_visible()

func OpenDiscord():
	OS.shell_open(LauncherCommons.SocialLink)

func DisplayFirstLogin():
	if LauncherCommons.isWeb:
		UICommons.MessageBox("""Welcome to Source of Mana!

You're currently playing the web version, which may run slower and isn't as stable as the downloadable versions.

This version is mainly here to showcase the game.
For the best experience, we recommend using the native client found on our itch.io page (Available on Windows, Linux, macOS, and Android).
""",
			settingsWindow.set_sessionfirstlogin.bind(false), "OK",
			OpenDiscord, "Join our Discord")
	else:
		UICommons.MessageBox("""Welcome to Source of Mana!

This is an open-source MMORPG and still a work in progress. You're welcome to explore, test, and enjoy the current features.

We're also always looking for contributors!
If you'd like to get involved in development, design, writing, or testing, feel free to join our community.
Otherwise, have fun and thank you for playing!
""",
			settingsWindow.set_sessionfirstlogin.bind(false), "OK",
			OpenDiscord, "Join our Discord")

#
func EnterLoginMenu():
	if progressTimer != null:
		progressTimer.stop()
		progressTimer = null

	infoContext.set_visible(false)
	menu.SetItemsVisible(false)
	stats.set_visible(false)
	statWindow.set_visible(false)
	dialogueContainer.set_visible(false)
	pickupPanel.set_visible(false)
	loadingControl.set_visible(false)
	menu.set_visible(false)
	actionBoxes.set_visible(false)
	quitWindow.set_visible(false)
	respawnWindow.EnableControl(false)
	shortcuts.set_visible(false)
	characterPanel.set_visible(false)
	buttonBoxes.set_visible(false)

	background.set_visible(true)
	loginPanel.set_visible(true)
	loginPanel.RefreshOnce()
	buttonBoxes.set_visible(true)

func EnterLoginProgress():
	loginPanel.set_visible(false)
	buttonBoxes.set_visible(false)

	progressTimer = Callback.SelfDestructTimer(self, NetworkCommons.LoginAttemptTimeout, TimeoutLoginProgress, [], "ProgressTimer")
	loadingControl.set_visible(true)

func TimeoutLoginProgress():
	Network.AuthError(NetworkCommons.AuthError.ERR_TIMEOUT)
	progressTimer = null

func EnterCharMenu():
	if progressTimer:
		progressTimer.stop()
		progressTimer = null

	loadingControl.set_visible(false)
	background.set_visible(false)
	loginPanel.set_visible(false)
	characterPanel.RefreshOnce()

	characterPanel.set_visible(true)
	buttonBoxes.set_visible(true)

func EnterCharProgress():
	characterPanel.set_visible(false)
	buttonBoxes.set_visible(false)

	progressTimer = Callback.SelfDestructTimer(self, NetworkCommons.CharSelectionTimeout, TimeoutCharProgress, [], "ProgressTimer")
	loadingControl.set_visible(true)

func TimeoutCharProgress():
	Network.CharacterError(NetworkCommons.CharacterError.ERR_TIMEOUT)
	progressTimer = null

func EnterGame():
	if progressTimer:
		progressTimer.stop()
		progressTimer = null
	loadingControl.set_visible(false)
	background.set_visible(false)

	Launcher.Camera.DisableSceneCamera()
	DisplayInfoContext(["gp_interact", "gp_untarget", "gp_morph", "gp_sit", "gp_target", "gp_pickup"])

	stats.set_visible(true)
	menu.set_visible(true)
	actionBoxes.set_visible(true)
	shortcuts.set_visible(true)

	menu.SetItemsVisible(true)
	stats.Init()
	statWindow.Init(Launcher.Player)

#
func _post_launch():
	if not FSM.enter_login.is_connected(EnterLoginMenu):
		FSM.enter_login.connect(EnterLoginMenu)
	if not FSM.enter_login_progress.is_connected(EnterLoginProgress):
		FSM.enter_login_progress.connect(EnterLoginProgress)
	if not FSM.enter_char.is_connected(EnterCharMenu):
		FSM.enter_char.connect(EnterCharMenu)
	if not FSM.enter_char_progress.is_connected(EnterCharProgress):
		FSM.enter_char_progress.connect(EnterCharProgress)
	if not FSM.enter_game.is_connected(EnterGame):
		FSM.enter_game.connect(EnterGame)
	FSM.EnterState(FSM.States.LOGIN_SCREEN)
	if minimapWindow:
		minimapWindow._post_launch()
	isInitialized = true

func Destroy():
	if minimapWindow:
		minimapWindow.Destroy()
	isInitialized = false

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
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

	assert(CRTShader.material != null, "CRT Shader can't load as its texture material is missing")
	CRTShader.material.set_shader_parameter("resolution", get_viewport().size / 2)

func _on_ui_margin_resized():
	if CRTShader and CRTShader.material:
		CRTShader.material.set_shader_parameter("resolution", get_viewport().size / 2)

	if settingsWindow:
		settingsWindow.set_fullscreen(DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN, false)
		settingsWindow.set_windowPos(DisplayServer.window_get_position(0), false)
		settingsWindow.set_resolution(DisplayServer.window_get_size(0), false)
