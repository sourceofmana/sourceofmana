extends WindowPanel

@onready var nameTextControl : LineEdit		= $Margin/VBoxContainer/GridContainer/NameContainer/NameText
@onready var passwordTextControl : LineEdit	= $Margin/VBoxContainer/GridContainer/PasswordContainer/PasswordText
@onready var warningLabel : RichTextLabel	= $Margin/VBoxContainer/Warning

@onready var onlineCheck : CheckBox			= $Margin/VBoxContainer/SignBar/OnlineButton
@onready var hostButton : Button			= $Margin/VBoxContainer/SignBar/Host
@onready var playButton : Button			= $Margin/VBoxContainer/SignBar/Play
@onready var registerButton : Button		= $Margin/VBoxContainer/SignBar/Register

#
func FillWarningLabel(warn : String):
	warningLabel.set_text("[color=#%s]%s[/color]" % [UICommons.WarnTextColor.to_html(false), warn])

#
func CheckNameSize(s : String) -> bool:
	var currentSize : int = s.length()
	return (currentSize >= NetworkCommons.PlayerNameMinSize && currentSize <= NetworkCommons.PlayerNameMaxSize)

func CheckNameValid(s : String) -> bool:
	var regex = RegEx.new()
	regex.compile(NetworkCommons.PlayerNameInvalidChar)
	var result = regex.search(s)
	return result == null

func CheckSignInInformation() -> bool:
	var ret : bool = true
	var nameText : String = nameTextControl.get_text()
	if not CheckNameSize(nameText):
		FillWarningLabel("Name length should be inbetween %s and %s character long" % [NetworkCommons.PlayerNameMinSize, NetworkCommons.PlayerNameMaxSize])
		ret = false
	elif not CheckNameValid(nameText):
		FillWarningLabel("Name should not include non alpha-numeric character")
		ret = false
	else:
		FillWarningLabel("")

	return ret

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
	if CheckSignInInformation() == true:
		if Launcher.GUI.settingsWindow:
			Launcher.GUI.settingsWindow.set_sessionaccountname(nameTextControl.get_text())
		Launcher.GUI.ToggleControl(self)
		Launcher.FSM.playerName = nameTextControl.get_text()
		Launcher.FSM.EnterState(Launcher.FSM.States.LOGIN_PROGRESS)
		Launcher.LaunchMode(true, not onlineCheck.button_pressed)

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
	FillWarningLabel("")

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
