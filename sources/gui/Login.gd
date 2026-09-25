extends Control

#
@onready var nameControl : Control					= $HBoxContainer/Panel/Margin/Content/LoginContainer/Name
@onready var nameTextControl : LineEdit				= $HBoxContainer/Panel/Margin/Content/LoginContainer/Name/Container/Text
@onready var passwordControl : Control				= $HBoxContainer/Panel/Margin/Content/LoginContainer/Password
@onready var passwordLabel : Label					= $HBoxContainer/Panel/Margin/Content/LoginContainer/Password/Label
@onready var passwordTextControl : LineEdit			= $HBoxContainer/Panel/Margin/Content/LoginContainer/Password/Container/Text
@onready var confirmPasswordControl : Control		= $HBoxContainer/Panel/Margin/Content/LoginContainer/ConfirmPassword
@onready var confirmPasswordTextControl : LineEdit	= $HBoxContainer/Panel/Margin/Content/LoginContainer/ConfirmPassword/Container/Text
@onready var emailControl : Control					= $HBoxContainer/Panel/Margin/Content/LoginContainer/Email
@onready var emailTextControl : LineEdit			= $HBoxContainer/Panel/Margin/Content/LoginContainer/Email/Container/Text
@onready var resetCodeControl : Control				= $HBoxContainer/Panel/Margin/Content/LoginContainer/Code
@onready var resetCodeTextControl : LineEdit		= $HBoxContainer/Panel/Margin/Content/LoginContainer/Code/Container/Text
@onready var indicatorRow : HBoxContainer			= $HBoxContainer/Panel/Margin/Content/LoginContainer/IndicatorRow
@onready var rememberMeCheckBox : CheckBox			= $HBoxContainer/Panel/Margin/Content/LoginContainer/IndicatorRow/RememberMe
@onready var onlineIndicator : CheckBox				= $HBoxContainer/Panel/Margin/Content/LoginContainer/IndicatorRow/OnlineIndicator
@onready var panel : PanelContainer					= $HBoxContainer/Panel
@onready var content : BoxContainer					= $HBoxContainer/Panel/Margin/Content
@onready var horizontalSeparator : HSeparator		= $HBoxContainer/Panel/Margin/Content/HSeparator2
@onready var verticalSeparator : VSeparator			= $HBoxContainer/Panel/Margin/Content/VSeparator
@onready var news : Scrollable						= $HBoxContainer/Panel/Margin/Content/News
@onready var agreement : Scrollable					= $HBoxContainer/Panel/Margin/Content/Agreement
@onready var fieldControls : Array[Control]			= [nameControl, passwordControl, confirmPasswordControl, emailControl, resetCodeControl]

enum RecoveryState { NONE, REQUEST_EMAIL, ENTER_CODE }

const CompactMaxHeight : int				= 700
const TwoColumnsMinWidth : int				= 820
const TwoColumnsRatio : float				= 8.0

var nameText : String						= ""
var savedToken : String						= ""
var savedAccountName : String				= ""
var fillingFields : bool					= false
var isAccountCreatorEnabled : bool			= false
var recoveryState : RecoveryState			= RecoveryState.NONE
var pendingFocusControl : Control			= null
var defaultPlaceholders : Dictionary		= {}

#
func FillWarningLabel(err : NetworkCommons.AuthError):
	if isAccountCreatorEnabled:
		FSM.EnterState(FSM.States.LOGIN_SCREEN)
		if err == NetworkCommons.AuthError.ERR_OK:
			EnableAccountCreator(false)
		else:
			EnableAccountCreator(true)
	elif recoveryState != RecoveryState.NONE:
		FSM.EnterState(FSM.States.LOGIN_SCREEN)
	else:
		if err != NetworkCommons.AuthError.ERR_OK:
			FSM.EnterState(FSM.States.LOGIN_SCREEN)

	var isWarn : bool = true
	var warn : String = ""
	match err:
		NetworkCommons.AuthError.ERR_OK:
			warn = ""
		NetworkCommons.AuthError.ERR_TOKEN:
			warn = "Invalid token, enter your password"
			passwordTextControl.clear()
			ClearSavedToken()
			RequestFocus(passwordTextControl)
		NetworkCommons.AuthError.ERR_DUPLICATE_CONNECTION:
			warn = "Another connection happened with the same login."
		NetworkCommons.AuthError.ERR_AUTH:
			warn = "Invalid account name or password."
			RequestFocus(passwordTextControl)
		NetworkCommons.AuthError.ERR_PASSWORD_VALID:
			warn = "Password should only include alpha-numeric characters and symbols."
			RequestFocus(passwordTextControl)
		NetworkCommons.AuthError.ERR_PASSWORD_SIZE:
			warn = "Password length should be inbetween %d and %d character long." % [NetworkCommons.PasswordMinSize, NetworkCommons.PasswordMaxSize]
			RequestFocus(passwordTextControl)
		NetworkCommons.AuthError.ERR_NAME_AVAILABLE:
			warn = "Account name not available."
			RequestFocus(nameTextControl)
		NetworkCommons.AuthError.ERR_NAME_VALID:
			warn = "Name should should only include alpha-numeric characters and symbols."
			RequestFocus(nameTextControl)
		NetworkCommons.AuthError.ERR_NAME_SIZE:
			warn = "Name length should be inbetween %d and %d character long." % [NetworkCommons.PlayerNameMinSize, NetworkCommons.PlayerNameMaxSize]
			RequestFocus(nameTextControl)
		NetworkCommons.AuthError.ERR_PASSWORD_MISMATCH:
			warn = "Passwords do not match."
			RequestFocus(confirmPasswordTextControl)
		NetworkCommons.AuthError.ERR_EMAIL_VALID:
			warn = "Email is incorrect, please us a normal email format."
			RequestFocus(emailTextControl)
		NetworkCommons.AuthError.ERR_RESET_UNAVAILABLE:
			warn = "Password reset is not available on this server."
			SetRecoveryState(RecoveryState.NONE)
		NetworkCommons.AuthError.ERR_RESET_EMAIL_SENT:
			warn = "If this email is registered, a reset code has been sent. Check your inbox."
			isWarn = false
			SetRecoveryState(RecoveryState.ENTER_CODE)
		NetworkCommons.AuthError.ERR_RESET_INVALID_CODE:
			warn = "Invalid or expired reset code."
			RequestFocus(resetCodeTextControl)
		NetworkCommons.AuthError.ERR_RESET_PASSWORD_UPDATED:
			warn = "Password updated successfully. You can now log in."
			isWarn = false
			SetRecoveryState(RecoveryState.NONE)
		_:
			warn = "Could not connect to the server (Error %d).\nPlease contact us via our [url=%s][color=#%s]Discord server[/color][/url].\nMeanwhile be sure to test the offline mode!" % [err, LauncherCommons.SocialLink, UICommons.DarkTextColor]

	var textColor : Color = UICommons.WarnTextColor if isWarn else UICommons.TextColor

	if not warn.is_empty():
		warn = "[color=#%s]%s[/color]" % [textColor.to_html(false), warn]
	Launcher.GUI.notificationLabel.AddNotification(warn)

func RequestFocus(control : Control):
	pendingFocusControl = control
	if control.is_visible_in_tree():
		ApplyFocus.call_deferred()

func ApplyFocus():
	if pendingFocusControl:
		pendingFocusControl.release_focus()
		pendingFocusControl.grab_focus()
		pendingFocusControl = null

func RefreshControls():
	var isRecovering : bool = recoveryState != RecoveryState.NONE
	var enteringCode : bool = recoveryState == RecoveryState.ENTER_CODE

	nameControl.set_visible(not enteringCode)
	passwordControl.set_visible(recoveryState != RecoveryState.REQUEST_EMAIL)
	confirmPasswordControl.set_visible(isAccountCreatorEnabled or enteringCode)
	emailControl.set_visible(isAccountCreatorEnabled)
	resetCodeControl.set_visible(enteringCode)
	indicatorRow.set_visible(not isAccountCreatorEnabled and not isRecovering)
	news.set_visible(not isAccountCreatorEnabled and not isRecovering)
	agreement.set_visible(isAccountCreatorEnabled)

	passwordLabel.text = "New Password" if enteringCode else "Password"
	passwordTextControl.secret = true

	SetPanelExpand(not isRecovering)
	RefreshFocusNodes(isAccountCreatorEnabled)
	RefreshLayout()
	EnableButtons(true)

func SetRecoveryState(state : RecoveryState):
	recoveryState = state
	isAccountCreatorEnabled = false
	RefreshControls()

	match recoveryState:
		RecoveryState.NONE:
			passwordTextControl.clear()
			confirmPasswordTextControl.clear()
			resetCodeTextControl.clear()
		RecoveryState.REQUEST_EMAIL:
			nameTextControl.grab_focus()
		RecoveryState.ENTER_CODE:
			passwordTextControl.clear()
			confirmPasswordTextControl.clear()
			resetCodeTextControl.grab_focus()

func EnableAccountCreator(enable : bool):
	recoveryState = RecoveryState.NONE
	isAccountCreatorEnabled = enable
	RefreshControls()

	if not enable:
		confirmPasswordTextControl.clear()

func RefreshLayout():
	var viewportSize : Vector2 = get_viewport_rect().size
	var sidePanel : Scrollable = agreement if isAccountCreatorEnabled else news
	var isShort : bool = viewportSize.y < CompactMaxHeight
	var isSqueezed : bool = isShort and sidePanel.is_visible()
	var twoColumns : bool = isSqueezed and viewportSize.x >= TwoColumnsMinWidth

	content.vertical = not twoColumns
	panel.size_flags_stretch_ratio = TwoColumnsRatio if twoColumns else 1.0
	horizontalSeparator.set_visible(sidePanel.is_visible() and not isShort)
	verticalSeparator.set_visible(twoColumns)
	SetCompactFields(isSqueezed and not twoColumns)

func SetCompactFields(compact : bool):
	for control : Control in fieldControls:
		var label : Label = control.get_node("Label")
		var text : LineEdit = control.get_node("Container/Text")
		if not defaultPlaceholders.has(control):
			defaultPlaceholders[control] = text.placeholder_text
		label.set_visible(not compact)
		text.placeholder_text = label.text if compact else defaultPlaceholders[control]

func SetPanelExpand(expand : bool):
	if expand:
		panel.size_flags_vertical = Control.SIZE_FILL
	else:
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

#
func RefreshFocusNodes(accountCreatorEnabled : bool):
	if accountCreatorEnabled:
		nameTextControl.set_focus_previous(emailTextControl.get_path())
		passwordTextControl.set_focus_next(confirmPasswordTextControl.get_path())
		confirmPasswordTextControl.set_focus_next(emailTextControl.get_path())
		confirmPasswordTextControl.set_focus_previous(passwordTextControl.get_path())
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
			if recoveryState == RecoveryState.REQUEST_EMAIL:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Send Code", RequestReset)
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "Cancel", SetRecoveryState.bind(RecoveryState.NONE))
			elif recoveryState == RecoveryState.ENTER_CODE:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Reset Password", ConfirmReset)
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "Cancel", SetRecoveryState.bind(RecoveryState.NONE))
			elif isAccountCreatorEnabled:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Create", CreateAccount)
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "Cancel", EnableAccountCreator.bind(false))
			else:
				if IsReturningPlayer():
					Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Connect", Connect)
					Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.SECONDARY, "Create Account", EnableAccountCreator.bind(true))
				else:
					Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Create Account", EnableAccountCreator.bind(true))
					Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.SECONDARY, "Connect", Connect)
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.TERTIARY, "Switch Online", SwitchOnlineMode.bind(onlineIndicator.button_pressed))
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "Forgot Password", SetRecoveryState.bind(RecoveryState.REQUEST_EMAIL))
				RefreshOnlineMode()
			RefreshServerButtons()
		else:
			onlineIndicator.text = "Connecting..."

# Every action behind these buttons needs the server, so they stay greyed out until the client is connected
func RefreshServerButtons():
	if not Launcher.GUI or not Launcher.GUI.buttonBoxes:
		return

	var reachable : bool = Network.IsServerReachable()
	Launcher.GUI.buttonBoxes.Enable(UICommons.ButtonBox.PRIMARY, reachable)
	if recoveryState == RecoveryState.NONE and not isAccountCreatorEnabled:
		Launcher.GUI.buttonBoxes.Enable(UICommons.ButtonBox.SECONDARY, reachable)
		Launcher.GUI.buttonBoxes.Enable(UICommons.ButtonBox.CANCEL, reachable)
		if not reachable and onlineIndicator:
			onlineIndicator.text = "Connecting..."

	if reachable:
		Launcher.GUI.buttonBoxes.Suggest(UICommons.ButtonBox.PRIMARY)
	else:
		Launcher.GUI.buttonBoxes.ClearSuggest()

func SaveAccountName():
	if Launcher.GUI.settingsWindow:
		Launcher.GUI.settingsWindow.set_sessionaccountname(nameText)

func IsReturningPlayer() -> bool:
	return not savedToken.is_empty() or not Conf.GetUserValue("Session-AccountName", "").is_empty()

func RefreshOnce():
	EnableAccountCreator(isAccountCreatorEnabled)
	_on_visibility_changed()

# Token persistence
func SaveToken(accountName : String, token : String):
	if not rememberMeCheckBox.button_pressed:
		return
	Conf.SetValue("auth", "account_name", Conf.Type.AUTH_TOKEN, accountName)
	Conf.SetValue("auth", "token", Conf.Type.AUTH_TOKEN, token)
	Conf.SaveType("auth_token", Conf.Type.AUTH_TOKEN)

func LoadSavedToken() -> bool:
	savedAccountName = Conf.GetString("auth", "account_name", Conf.Type.AUTH_TOKEN)
	savedToken = Conf.GetString("auth", "token", Conf.Type.AUTH_TOKEN)
	if savedAccountName.is_empty() or savedToken.is_empty():
		return false
	nameText = savedAccountName
	return true

func ClearSavedToken():
	passwordTextControl.clear()
	savedToken = ""
	savedAccountName = ""
	Conf.confFiles[Conf.Type.AUTH_TOKEN].clear()
	Conf.cache.clear()
	DirAccess.remove_absolute(Path.Local + "auth_token" + Path.ConfExt)

func FillFieldsFromToken():
	if savedToken.is_empty():
		return

	fillingFields = true
	nameTextControl.set_text(nameText)
	passwordTextControl.set_text("tokentokentoken")
	fillingFields = false

#
func Connect():
	if not Network.IsServerReachable():
		FillWarningLabel(NetworkCommons.AuthError.ERR_SERVER_UNREACHABLE)
		return

	nameText = nameTextControl.get_text()
	if not savedToken.is_empty():
		if Network.LoginWithToken(savedAccountName, savedToken, NetworkCommons.GetPlatform()):
			nameText = savedAccountName
			savedToken = ""
			FSM.EnterState(FSM.States.LOGIN_PROGRESS)
		return
	var passwordText : String = passwordTextControl.get_text()
	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	FillWarningLabel(authError)
	if authError == NetworkCommons.AuthError.ERR_OK:
		if Network.LoginWithPassword(nameText, passwordText, rememberMeCheckBox.button_pressed, NetworkCommons.GetPlatform()):
			FSM.EnterState(FSM.States.LOGIN_PROGRESS)

func CreateAccount():
	if not Network.IsServerReachable():
		FillWarningLabel(NetworkCommons.AuthError.ERR_SERVER_UNREACHABLE)
		return

	nameText = nameTextControl.get_text()
	var passwordText : String = passwordTextControl.get_text()
	var confirmText : String = confirmPasswordTextControl.get_text()
	var emailText : String = emailTextControl.get_text()

	var authError : NetworkCommons.AuthError = NetworkCommons.CheckAuthInformation(nameText, passwordText)
	if authError == NetworkCommons.AuthError.ERR_OK:
		if passwordText != confirmText:
			authError = NetworkCommons.AuthError.ERR_PASSWORD_MISMATCH
	if authError == NetworkCommons.AuthError.ERR_OK:
		authError = NetworkCommons.CheckEmailInformation(emailText)

	if authError == NetworkCommons.AuthError.ERR_OK:
		if Network.CreateAccount(nameText, passwordText, emailText, rememberMeCheckBox.button_pressed, NetworkCommons.GetPlatform()):
			FSM.EnterState(FSM.States.LOGIN_PROGRESS)
	else:
		FillWarningLabel(authError)

func RequestReset():
	if not Network.IsServerReachable():
		FillWarningLabel(NetworkCommons.AuthError.ERR_SERVER_UNREACHABLE)
		return

	nameText = nameTextControl.get_text()
	if nameText.is_empty():
		nameTextControl.grab_focus()
		return
	Network.RequestPasswordReset(nameText)

func ConfirmReset():
	if not Network.IsServerReachable():
		FillWarningLabel(NetworkCommons.AuthError.ERR_SERVER_UNREACHABLE)
		return

	var codeText : String = resetCodeTextControl.get_text()
	var newPassword : String = passwordTextControl.get_text()
	var confirmText : String = confirmPasswordTextControl.get_text()

	if not NetworkCommons.CheckResetCode(codeText):
		FillWarningLabel(NetworkCommons.AuthError.ERR_RESET_INVALID_CODE)
		return

	var passwordErr : NetworkCommons.AuthError = NetworkCommons.CheckPasswordInformation(newPassword)
	if passwordErr != NetworkCommons.AuthError.ERR_OK:
		FillWarningLabel(passwordErr)
		return

	if newPassword != confirmText:
		FillWarningLabel(NetworkCommons.AuthError.ERR_PASSWORD_MISMATCH)
		return

	Network.ConfirmPasswordReset(nameText, codeText, newPassword)

func Close():
	if recoveryState != RecoveryState.NONE:
		SetRecoveryState(RecoveryState.NONE)
	elif isAccountCreatorEnabled:
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

func _on_text_submitted(_newText):
	Launcher.GUI.buttonBoxes.Call(UICommons.ButtonBox.PRIMARY)

#
func _on_visibility_changed():
	if visible:
		LoadSavedToken()
		FillFieldsFromToken()
		if pendingFocusControl and pendingFocusControl.is_visible_in_tree():
			ApplyFocus.call_deferred()
		elif nameTextControl and nameTextControl.is_visible() and nameTextControl.get_text().length() == 0:
			nameTextControl.grab_focus()
		elif passwordTextControl and passwordTextControl.is_visible() and passwordTextControl.get_text().length() == 0:
			passwordTextControl.grab_focus()
		EnableButtons(true)

func SwitchOnlineMode(toggled : bool):
	EnableButtons(true)
	if Launcher.Mode(true, toggled):
		EnableButtons(false)

func _on_password_text_changed(_newText : String):
	if not fillingFields:
		savedToken = ""

func _on_remember_me_toggled(toggled_on : bool):
	if not toggled_on:
		ClearSavedToken()

func _ready():
	Launcher.launchModeUpdated.connect(OnlineMode)
	get_viewport().size_changed.connect(RefreshLayout)
	RefreshLayout()
	if LoadSavedToken():
		rememberMeCheckBox.button_pressed = true
