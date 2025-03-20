extends Control

#
@onready var nameControl : Control			= $HBoxContainer/Panel/Margin/VBoxContainer/LoginContainer/Name
@onready var nameTextControl : LineEdit		= $HBoxContainer/Panel/Margin/VBoxContainer/LoginContainer/Name/Container/Text
@onready var passwordControl : Control		= $HBoxContainer/Panel/Margin/VBoxContainer/LoginContainer/Password
@onready var passwordTextControl : LineEdit	= $HBoxContainer/Panel/Margin/VBoxContainer/LoginContainer/Password/Container/Text
@onready var emailControl : Control			= $HBoxContainer/Panel/Margin/VBoxContainer/LoginContainer/Email
@onready var emailTextControl : LineEdit	= $HBoxContainer/Panel/Margin/VBoxContainer/LoginContainer/Email/Container/Text
@onready var onlineIndicator : CheckBox		= $HBoxContainer/Panel/Margin/VBoxContainer/LoginContainer/OnlineIndicator
@onready var news : Scrollable				= $HBoxContainer/Panel/Margin/VBoxContainer/News
@onready var agreement : Scrollable			= $HBoxContainer/Panel/Margin/VBoxContainer/Agreement

var isAccountCreatorEnabled : bool			= false
var nameText : String = ""

#
func FillWarningLabel(err : NetworkCommons.AuthError):
	if isAccountCreatorEnabled:
		FSM.EnterState(FSM.States.LOGIN_SCREEN)
		if err == NetworkCommons.AuthError.ERR_OK:
			EnableAccountCreator(false)
		else:
			EnableAccountCreator(true)
	else:
		if err != NetworkCommons.AuthError.ERR_OK:
			FSM.EnterState(FSM.States.LOGIN_SCREEN)

	var warn : String = ""
	match err:
		NetworkCommons.AuthError.ERR_OK:
			warn = ""
		NetworkCommons.AuthError.ERR_DUPLICATE_CONNECTION:
			warn = "Another connection happened with the same login."
		NetworkCommons.AuthError.ERR_AUTH:
			warn = "Invalid account name or password."
			passwordTextControl.grab_focus()
		NetworkCommons.AuthError.ERR_PASSWORD_VALID:
			warn = "Password should only include alpha-numeric characters and symbols."
			passwordTextControl.grab_focus()
		NetworkCommons.AuthError.ERR_PASSWORD_SIZE:
			warn = "Password length should be inbetween %d and %d character long." % [NetworkCommons.PasswordMinSize, NetworkCommons.PasswordMaxSize]
			passwordTextControl.grab_focus()
		NetworkCommons.AuthError.ERR_NAME_AVAILABLE:
			warn = "Account name not available."
			nameTextControl.grab_focus()
		NetworkCommons.AuthError.ERR_NAME_VALID:
			warn = "Name should should only include alpha-numeric characters and symbols."
			nameTextControl.grab_focus()
		NetworkCommons.AuthError.ERR_NAME_SIZE:
			warn = "Name length should be inbetween %d and %d character long." % [NetworkCommons.PlayerNameMinSize, NetworkCommons.PlayerNameMaxSize]
			nameTextControl.grab_focus()
		NetworkCommons.AuthError.ERR_EMAIL_VALID:
			warn = "Email is incorrect, please us a normal email format."
			emailTextControl.grab_focus()
		_:
			warn = "Could not connect to the server (Error %d).\nPlease contact us via our [url=%s][color=#%s]Discord server[/color][/url].\nMeanwhile be sure to test the offline mode!" % [err, LauncherCommons.SocialLink, UICommons.DarkTextColor]

	if not warn.is_empty():
		warn = "[color=#%s]%s[/color]" % [UICommons.WarnTextColor.to_html(false), warn]
	Launcher.GUI.notificationLabel.AddNotification(warn)

func EnableAccountCreator(enable : bool):
	isAccountCreatorEnabled = enable

	emailControl.set_visible(isAccountCreatorEnabled)
	agreement.set_visible(isAccountCreatorEnabled)

	onlineIndicator.set_visible(not isAccountCreatorEnabled)
	news.set_visible(not isAccountCreatorEnabled)
	EnableButtons(true)
	RefreshFocusNodes(enable)

#
func RefreshFocusNodes(accountCreatorEnabled : bool):
	if accountCreatorEnabled:
		nameTextControl.set_focus_previous(emailTextControl.get_path())
		passwordTextControl.set_focus_next(emailTextControl.get_path())
	else:
		nameTextControl.set_focus_previous(passwordTextControl.get_path())
		passwordTextControl.set_focus_next(nameTextControl.get_path())

func RefreshOnlineMode():
	OnlineMode(Network.Client != null, Network.ENetServer != null or Network.WebSocketServer != null)

func OnlineMode(_clientStarted : bool, serverStarted : bool):
	if onlineIndicator:
		Launcher.GUI.buttonBoxes.Rename(UICommons.ButtonBox.TERTIARY, "Switch Online" if serverStarted else "Switch Offline")
		onlineIndicator.text = "Playing Offline" if serverStarted else "Playing Online"
		if onlineIndicator.button_pressed != not serverStarted:
			onlineIndicator.button_pressed = not serverStarted

func EnableButtons(state : bool):
	if Launcher.GUI and Launcher.GUI.buttonBoxes:
		Launcher.GUI.buttonBoxes.ClearAll()
		if state:
			if isAccountCreatorEnabled:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Create", CreateAccount)
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "Cancel", EnableAccountCreator.bind(false))
			else:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Connect", Connect)
				if LauncherCommons.isWeb:
					Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.TERTIARY, "Refresh Connection", SwitchOnlineMode.bind(true))
				else:
					Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.TERTIARY, "Switch Online", SwitchOnlineMode.bind(onlineIndicator.button_pressed))
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.SECONDARY, "Create Account", EnableAccountCreator.bind(true))
				RefreshOnlineMode()
		else:
			onlineIndicator.text = "Connecting..."

func RefreshOnce():
	EnableAccountCreator(isAccountCreatorEnabled)
	_on_visibility_changed()

#
func Connect():
	nameText = nameTextControl.get_text()
	var passwordText : String = passwordTextControl.get_text()
	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)
	if authError == NetworkCommons.AuthError.ERR_OK:
		if Network.ConnectAccount(nameText, passwordText):
			FSM.EnterState(FSM.States.LOGIN_PROGRESS)
			if Launcher.GUI.settingsWindow:
				Launcher.GUI.settingsWindow.set_sessionaccountname(nameText)

func CreateAccount():
	nameText = nameTextControl.get_text()
	var passwordText : String = passwordTextControl.get_text()
	var emailText : String = emailTextControl.get_text()

	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	if authError == NetworkCommons.AuthError.ERR_OK:
		authError = NetworkCommons.CheckEmailInformation(emailText)

	if authError == NetworkCommons.AuthError.ERR_OK:
		if Network.CreateAccount(nameText, passwordText, emailText):
			FSM.EnterState(FSM.States.LOGIN_PROGRESS)
	else:
		FillWarningLabel(authError)

func Close():
	if isAccountCreatorEnabled:
		EnableAccountCreator(false)
	else:
		Launcher.GUI.ToggleControl(Launcher.GUI.quitWindow)

#
func _on_text_focus_entered():
	if Launcher.Action:
		Launcher.Action.Enable(false)

func _on_text_focus_exited():
	if Launcher.Action:
		Launcher.Action.Enable(true)

func _on_text_submitted(_new_text):
	Launcher.GUI.buttonBoxes.Call(UICommons.ButtonBox.PRIMARY)

#
func _on_visibility_changed():
	if visible:
		if nameTextControl and nameTextControl.is_visible() and nameTextControl.get_text().length() == 0:
			nameTextControl.grab_focus()
		elif passwordTextControl and passwordTextControl.is_visible() and passwordTextControl.get_text().length() == 0:
			passwordTextControl.grab_focus()
		EnableButtons(true)

func SwitchOnlineMode(toggled : bool):
	EnableButtons(true)
	if Launcher.Mode(true, toggled):
		EnableButtons(false)

func _ready():
	Launcher.launchModeUpdated.connect(OnlineMode)
