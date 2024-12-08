extends WindowPanel

#
@onready var nameTextControl : LineEdit		= $Margin/VBoxContainer/GridContainer/NameContainer/NameText
@onready var passwordTextControl : LineEdit	= $Margin/VBoxContainer/GridContainer/PasswordContainer/PasswordText

@onready var onlineCheck : CheckBox			= $Margin/VBoxContainer/SignBar/OnlineButton
@onready var playButton : Button			= $Margin/VBoxContainer/SignBar/Play
@onready var registerButton : Button		= $Margin/VBoxContainer/SignBar/Register

var nameText : String = ""
var passwordText : String = ""

#
func FillWarningLabel(err : NetworkCommons.AuthError):
	var warn : String = ""
	match err:
		NetworkCommons.AuthError.ERR_OK:
			warn = ""
		NetworkCommons.AuthError.ERR_AUTH:
			warn = "Invalid account name or password."
		NetworkCommons.AuthError.ERR_PASSWORD_VALID:
			warn = "Password should only include alpha-numeric characters and symbols."
		NetworkCommons.AuthError.ERR_PASSWORD_SIZE:
			warn = "Password length should be inbetween %d and %d character long." % [NetworkCommons.PasswordMinSize, NetworkCommons.PasswordMaxSize]
		NetworkCommons.AuthError.ERR_NAME_AVAILABLE:
			warn = "Account name not available."
		NetworkCommons.AuthError.ERR_NAME_VALID:
			warn = "Name should should only include alpha-numeric characters and symbols."
		NetworkCommons.AuthError.ERR_NAME_SIZE:
			warn = "Name length should be inbetween %d and %d character long." % [NetworkCommons.PlayerNameMinSize, NetworkCommons.PlayerNameMaxSize]
		_:
			warn = "Could not connect to the server (Error %d).\nPlease contact us via our [url=%s][color=#%s]Discord server[/color][/url].\nMeanwhile be sure to test the offline mode!" % [err, LauncherCommons.SocialLink, UICommons.DarkTextColor]

	if not warn.is_empty():
		warn = "[color=#%s]%s[/color]" % [UICommons.WarnTextColor.to_html(false), warn]
	Launcher.GUI.notificationLabel.AddNotification(warn)

#
func _warning_on_meta_clicked(meta):
	OS.shell_open(str(meta))

#
func EnableControl(state : bool):
	super(state)

	if state == true:
		if OS.get_name() == "Web":
			onlineCheck.visible = false

func RefreshOnlineMode():
	OnlineMode(Network.Client != null, Network.Server != null)

func OnlineMode(_clientStarted : bool, serverStarted : bool):
	if onlineCheck:
		onlineCheck.text = "Offline" if serverStarted else "Online"
		if onlineCheck.button_pressed != not serverStarted:
			onlineCheck.button_pressed = not serverStarted

func EnableButtons(state : bool):
	var isDisabled : bool = not state
	onlineCheck.disabled = isDisabled
	playButton.disabled = isDisabled
	registerButton.disabled = isDisabled
	if isDisabled:
		onlineCheck.text = "Connecting..."
	else:
		RefreshOnlineMode()

#
func _on_play_pressed():
	nameText = nameTextControl.get_text()
	passwordText = passwordTextControl.get_text()
	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)
	if authError == NetworkCommons.AuthError.ERR_OK:
		FSM.EnterState(FSM.States.LOGIN_PROGRESS)
		Network.ConnectAccount(nameText, passwordText)
		if Launcher.GUI.settingsWindow:
			Launcher.GUI.settingsWindow.set_sessionaccountname(nameText)

func _on_register_pressed():
	nameText = nameTextControl.get_text()
	passwordText = passwordTextControl.get_text()

	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)

	if authError == NetworkCommons.AuthError.ERR_OK:
		Network.CreateAccount(nameText, passwordText, "g@g.g")

#
func _on_text_focus_entered():
	SetFloatingWindowToTop()
	if Launcher.Action:
		Launcher.Action.Enable(false)

func _on_text_focus_exited():
	if Launcher.Action:
		Launcher.Action.Enable(true)

func _on_text_submitted(_new_text):
	_on_play_pressed()

#
func _on_visibility_changed():
	if visible:
		if nameTextControl and nameTextControl.is_visible() and nameTextControl.get_text().length() == 0:
			nameTextControl.grab_focus()
		elif passwordTextControl and passwordTextControl.is_visible() and passwordTextControl.get_text().length() == 0:
			passwordTextControl.grab_focus()
		elif playButton and playButton.is_visible():
			playButton.grab_focus()
		RefreshOnlineMode()

func _on_online_button_toggled(toggled : bool):
	var emulateServer : bool = not toggled
	EnableButtons(false)
	if not Launcher.Mode(true, emulateServer):
		EnableButtons(true)

func _ready():
	Launcher.launchModeUpdated.connect(OnlineMode)
