extends WindowPanel

@onready var nameTextControl : LineEdit		= $Margin/VBoxContainer/GridContainer/NameContainer/NameText
@onready var passwordTextControl : LineEdit	= $Margin/VBoxContainer/GridContainer/PasswordContainer/PasswordText
@onready var warningLabel : Label			= $Margin/VBoxContainer/Warning

@onready var onlineCheck : CheckButton		= $Margin/VBoxContainer/SignBar/OnlineButton
@onready var hostButton : Button			= $Margin/VBoxContainer/SignBar/Host
@onready var playButton : Button			= $Margin/VBoxContainer/SignBar/Play
@onready var registerButton : Button		= $Margin/VBoxContainer/SignBar/Register

#
func FillWarningLabel(warn : String):
	warningLabel.set_text(warn)

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
	return ret

#
func EnableControl(state : bool):
	super(state)

	if state == true:
		if not OS.is_debug_build():
			hostButton.visible = false
		else:
			onlineCheck.button_pressed = false

		if OS.get_name() == "Web":
			onlineCheck.button_pressed = false
			onlineCheck.visible = false

		if nameTextControl.get_text().length() == 0:
			nameTextControl.grab_focus()
		elif passwordTextControl.get_text().length() == 0:
			passwordTextControl.grab_focus()
		else:
			playButton.grab_focus()

#
func _on_play_pressed():
	if CheckSignInInformation() == true:
		Launcher.GUI.ToggleControl(self)
		Launcher.FSM.playerName = nameTextControl.get_text()
		Launcher.FSM.EnterState(Launcher.FSM.States.CHAR_SELECTION)
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
