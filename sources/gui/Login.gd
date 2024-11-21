extends WindowPanel

#
@onready var nameTextControl : LineEdit		= $Margin/VBoxContainer/GridContainer/NameContainer/NameText
@onready var passwordTextControl : LineEdit	= $Margin/VBoxContainer/GridContainer/PasswordContainer/PasswordText
@onready var warningLabel : RichTextLabel	= $Margin/VBoxContainer/Warning

@onready var onlineCheck : CheckBox			= $Margin/VBoxContainer/SignBar/OnlineButton
@onready var hostButton : Button			= $Margin/VBoxContainer/SignBar/Host
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
	warningLabel.set_text(warn)

#
func _warning_on_meta_clicked(meta):
	OS.shell_open(str(meta))

#
func EnableControl(state : bool):
	super(state)

	if state == true:
		if not OS.is_debug_build():
			hostButton.visible = false
		else:
			_on_online_button_toggled(false)

		if OS.get_name() == "Web":
			_on_online_button_toggled(false)
			onlineCheck.visible = false

#
func _on_play_pressed():
	nameText = nameTextControl.get_text()
	passwordText = passwordTextControl.get_text()

	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)

	if authError == NetworkCommons.AuthError.ERR_OK:
		Launcher.GUI.ToggleControl(self)
		if Launcher.GUI.settingsWindow:
			Launcher.GUI.settingsWindow.set_sessionaccountname(nameText)
		Launcher.LaunchMode(true, not onlineCheck.button_pressed)
		Launcher.FSM.EnterState(Launcher.FSM.States.LOGIN_PROGRESS)

func _on_register_pressed():
	nameText = nameTextControl.get_text()
	passwordText = passwordTextControl.get_text()

	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)

	if authError == NetworkCommons.AuthError.ERR_OK:
		Launcher.Network.CreateAccount(nameText, passwordText, "g@g.g")

func _on_host_pressed():
		Launcher.GUI.ToggleControl(self)
		Launcher.LaunchMode(false, true)

#
func _on_text_focus_entered():
	SetFloatingWindowToTop()
	Launcher.Action.Enable(false)

func _on_text_focus_exited():
	Launcher.Action.Enable(true)

func _on_text_submitted(_new_text):
	_on_play_pressed()

#
func _ready():
	FillWarningLabel(NetworkCommons.AuthError.ERR_OK)

func _on_visibility_changed():
	if visible:
		if nameTextControl and nameTextControl.is_visible() and nameTextControl.get_text().length() == 0:
			nameTextControl.grab_focus()
		elif passwordTextControl and passwordTextControl.is_visible() and passwordTextControl.get_text().length() == 0:
			passwordTextControl.grab_focus()
		elif playButton and playButton.is_visible():
			playButton.grab_focus()

func _on_online_button_toggled(toggled):
	onlineCheck.button_pressed = toggled
	onlineCheck.text = "Online" if toggled else "Offline"
