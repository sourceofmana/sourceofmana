extends Control

#
@onready var nameTextControl : LineEdit		= $Panel/Margin/VBoxContainer/GridContainer/NameContainer/NameText
@onready var passwordTextControl : LineEdit	= $Panel/Margin/VBoxContainer/GridContainer/PasswordContainer/PasswordText
@onready var onlineIndicator : CheckBox		= $Panel/Margin/VBoxContainer/OnlineIndicator

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
func RefreshOnlineMode():
	OnlineMode(Network.Client != null, Network.Server != null)

func OnlineMode(_clientStarted : bool, serverStarted : bool):
	if onlineIndicator:
		Launcher.GUI.buttonBoxes.Rename(UICommons.ButtonBox.LEFT, "Switch Online" if serverStarted else "Switch Offline")
		onlineIndicator.text = "Playing Offline" if serverStarted else "Playing Online"
		if onlineIndicator.button_pressed != not serverStarted:
			onlineIndicator.button_pressed = not serverStarted

func EnableButtons(state : bool):
	if Launcher.GUI and Launcher.GUI.buttonBoxes:
		if state:
			if OS.get_name() != "Web":
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.LEFT, "Switch Online", SwitchOnlineMode.bind(onlineIndicator.button_pressed))
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.MIDDLE, "Create Account", CreateAccount)
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.RIGHT, "Connect", Connect)
			RefreshOnlineMode()
		else:
			Launcher.GUI.buttonBoxes.ClearAll()
			onlineIndicator.text = "Connecting..."

#
func Connect():
	nameText = nameTextControl.get_text()
	passwordText = passwordTextControl.get_text()
	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)
	if authError == NetworkCommons.AuthError.ERR_OK:
		FSM.EnterState(FSM.States.LOGIN_PROGRESS)
		Network.ConnectAccount(nameText, passwordText)
		if Launcher.GUI.settingsWindow:
			Launcher.GUI.settingsWindow.set_sessionaccountname(nameText)

func CreateAccount():
	nameText = nameTextControl.get_text()
	passwordText = passwordTextControl.get_text()

	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)

	if authError == NetworkCommons.AuthError.ERR_OK:
		Network.CreateAccount(nameText, passwordText, "g@g.g")

#
func _on_text_focus_entered():
	if Launcher.Action:
		Launcher.Action.Enable(false)

func _on_text_focus_exited():
	if Launcher.Action:
		Launcher.Action.Enable(true)

func _on_text_submitted(_new_text):
	Connect()

#
func _on_visibility_changed():
	if visible:
		if nameTextControl and nameTextControl.is_visible() and nameTextControl.get_text().length() == 0:
			nameTextControl.grab_focus()
		elif passwordTextControl and passwordTextControl.is_visible() and passwordTextControl.get_text().length() == 0:
			passwordTextControl.grab_focus()
		elif Launcher.GUI.buttonBoxes:
			Launcher.GUI.buttonBoxes.Focus(UICommons.ButtonBox.RIGHT)
		EnableButtons(true)

func SwitchOnlineMode(toggled : bool):
	var emulateServer : bool = not toggled
	EnableButtons(true)
	if not Launcher.Mode(true, emulateServer):
		EnableButtons(false)

func _ready():
	Launcher.launchModeUpdated.connect(OnlineMode)
