extends WindowPanel

@onready var nameTextControl : LineEdit		= $VBoxContainer/GridContainer/NameContainer/NameText
@onready var passwordTextControl : LineEdit	= $VBoxContainer/GridContainer/PasswordContainer/PasswordText
@onready var warningLabel : Label			= $VBoxContainer/Warning

@onready var onlineCheck : CheckButton		= $"VBoxContainer/SignBar/OnlineButton"
@onready var hostButton : Button			= $VBoxContainer/SignBar/Host
@onready var playButton : Button			= $VBoxContainer/SignBar/Play
@onready var registerButton : Button		= $VBoxContainer/SignBar/Register

#
func FillWarningLabel(warn : String):
	warningLabel.set_text(warn)

#
func CheckNameSize(s : String) -> bool:
	var minNameSize : int = Launcher.Conf.GetInt("Login", "playerNameMinSize", Launcher.Conf.Type.AUTH)
	var maxNameSize : int = Launcher.Conf.GetInt("Login", "playerNameMaxSize", Launcher.Conf.Type.AUTH)
	var currentSize : int = s.length()
	return (currentSize >= minNameSize && currentSize <= maxNameSize)

func CheckNameValid(s : String) -> bool:
	var invalidCharRegex : String = Launcher.Conf.GetString("Login", "playerNameInvalidChar", Launcher.Conf.Type.AUTH)
	var regex = RegEx.new()
	regex.compile(invalidCharRegex)
	var result = regex.search(s)
	return result == null

func CheckSignInInformation() -> bool:
	var ret : bool = true
	var nameText : String = nameTextControl.get_text()
	if not CheckNameSize(nameText):
		var minNameSize : int = Launcher.Conf.GetInt("Login", "playerNameMinSize", Launcher.Conf.Type.AUTH)
		var maxNameSize : int = Launcher.Conf.GetInt("Login", "playerNameMaxSize", Launcher.Conf.Type.AUTH)
		FillWarningLabel("Name length should be inbetween %s and %s character long" % [minNameSize, maxNameSize])
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
