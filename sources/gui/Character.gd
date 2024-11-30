extends Control

#
@onready var characterNameLineEdit : LineEdit			= $PlayerName/MarginContainer/VBoxContainer/Entry
@onready var characterNameDisplay : Label				= $PlayerName/MarginContainer/VBoxContainer/Name
@onready var traitsPanel : PanelContainer				= $Customization/Traits
@onready var attributesPanel : PanelContainer			= $Customization/Attributes
@onready var statsPanel : PanelContainer				= $Customization/Stats

var isCharacterCreatorEnabled : bool					= false

#
func FillWarningLabel(err : NetworkCommons.CharacterError):
	var warn : String = ""
	match err:
		NetworkCommons.CharacterError.ERR_OK:
			warn = ""
			EnableCharacterCreator(false)
		NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN:
			warn = "Character is already logged in."
		NetworkCommons.CharacterError.ERR_TIMEOUT:
			warn = "Could not connect to the server (Error %d)." % err
		NetworkCommons.CharacterError.ERR_MISSING_PARAMS:
			warn = "Some character information are missing."
		NetworkCommons.CharacterError.ERR_NAME_AVAILABLE:
			warn = "Character name not available."
		NetworkCommons.CharacterError.ERR_NAME_VALID:
			warn = "Name should should only include alpha-numeric characters and symbols."
		NetworkCommons.CharacterError.ERR_NAME_SIZE:
			warn = "Name length should be inbetween %d and %d character long." % [NetworkCommons.PlayerNameMinSize, NetworkCommons.PlayerNameMaxSize]
		_:
			warn = "Unknown character issue (Error %d).\nPlease contact us via our [url=%s][color=#%s]Discord server[/color][/url].\n" % [err, LauncherCommons.SocialLink, UICommons.DarkTextColor]

	if not warn.is_empty():
		warn = "[color=#%s]%s[/color]" % [UICommons.WarnTextColor.to_html(false), warn]
	Launcher.GUI.notificationLabel.AddNotification(warn)

func AddCharacter(info : Dictionary):
	if "nickname" not in info or "level" not in info:
		assert(false, "Missing character information")
	else:
		UpdateSelectedCharacter(info)

func RandomizeCharacter():
	pass

func CreateCharacter():
	if isCharacterCreatorEnabled:
		var nickname : String = characterNameLineEdit.get_text()
		var err : NetworkCommons.CharacterError = NetworkCommons.CheckCharacterInformation(nickname)
		if err != NetworkCommons.CharacterError.ERR_OK:
			FillWarningLabel(err)
		else:
			Launcher.Network.CreateCharacter(nickname, {
				"hairstyle" = 0,
				"haircolor" = 0,
				"race" = 0,
				"skin" = 0,
				"gender" = 0,
				"shape" = "Default Entity",
				"spirit" = "Piou"
			})
			Launcher.FSM.EnterState(Launcher.FSM.States.CHAR_PROGRESS)

func SelectCharacter():
	Launcher.Network.ConnectCharacter(characterNameDisplay.get_text())
	Launcher.FSM.EnterState(Launcher.FSM.States.CHAR_PROGRESS)

func UpdateSelectedCharacter(info : Dictionary):
	if "nickname" in info:
		characterNameDisplay.set_text(info["nickname"])

func EnableCharacterCreator(enable : bool):
	isCharacterCreatorEnabled = enable
	statsPanel.set_visible(!enable)
	characterNameDisplay.set_visible(!enable)
	characterNameLineEdit.set_visible(enable)
	traitsPanel.set_visible(enable)
	attributesPanel.set_visible(enable)

	Launcher.GUI.buttonBoxes.ClearAll()
	if enable:
		Launcher.GUI.buttonBoxes.SetLeft("Cancel", EnableCharacterCreator.bind(false))
		Launcher.GUI.buttonBoxes.SetMiddle("Randomize", RandomizeCharacter)
		Launcher.GUI.buttonBoxes.SetRight("Create", CreateCharacter)
	else:
		Launcher.GUI.buttonBoxes.SetLeft("Cancel", Launcher.FSM.EnterState.bind(Launcher.FSM.States.LOGIN_SCREEN))
		Launcher.GUI.buttonBoxes.SetMiddle("New Player", EnableCharacterCreator.bind(true))
		Launcher.GUI.buttonBoxes.SetRight("Select", SelectCharacter)
