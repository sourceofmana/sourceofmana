extends Control

#
@onready var characterNameLineEdit : LineEdit			= $PlayerName/MarginContainer/VBoxContainer/Entry
@onready var characterNameDisplay : Label				= $PlayerName/MarginContainer/VBoxContainer/Name
@onready var traitsPanel : PanelContainer				= $Customization/Traits
@onready var attributesPanel : PanelContainer			= $Customization/Attributes
@onready var statsPanel : PanelContainer				= $Customization/Stats

var isCharacterCreatorEnabled : bool					= false
var characters : Array[Dictionary]						= []
var currentCharacterID : int							= -1

#
func FillWarningLabel(err : NetworkCommons.CharacterError):
	if isCharacterCreatorEnabled:
		FSM.EnterState(FSM.States.CHAR_SCREEN)
		if err == NetworkCommons.CharacterError.ERR_OK:
			EnableCharacterCreator(false)
		else:
			EnableCharacterCreator(true)

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

func VerifyCharacterInfo(info : Dictionary):
	return "nickname" in info and "last_timestamp" in info

func AddCharacter(info : Dictionary):
	if not VerifyCharacterInfo(info):
		assert(false, "Could not verify character info")
		return

	var entity : Entity = Instantiate.CreateEntity(ActorCommons.Type.PLAYER, "Default Entity", info["nickname"], false)
	if not entity:
		assert(false, "Could not create character preview")
		return

	var availableSlot : int = -1
	for charID in characters.size():
		if characters[charID].is_empty():
			availableSlot = charID
			break

	if availableSlot == -1:
		assert(false, "No free available placement")
		return

	characters[availableSlot] = info

	Launcher.Map.AddChild(entity)
	var randDir : Vector2 = Vector2(randf_range(-1.0, 1.0), 0.5)
	var randState : ActorCommons.State = ActorCommons.State.IDLE if randi() % 2 == 1 else ActorCommons.State.SIT
	entity.Update(Vector2.ZERO, ActorCommons.CharacterScreenLocations[availableSlot], randDir, randState, -1, true)

	if currentCharacterID == -1 or \
	characters[currentCharacterID]["last_timestamp"] == null or \
	(info["last_timestamp"] != null and characters[currentCharacterID]["last_timestamp"] < info["last_timestamp"]):
		UpdateSelectedCharacter(info, availableSlot)

func RandomizeCharacter():
	pass

func CreateCharacter():
	if isCharacterCreatorEnabled:
		var nickname : String = characterNameLineEdit.get_text()
		var err : NetworkCommons.CharacterError = NetworkCommons.CheckCharacterInformation(nickname)
		if err != NetworkCommons.CharacterError.ERR_OK:
			FillWarningLabel(err)
		else:
			Network.CreateCharacter(nickname, {
				"hairstyle" = 0,
				"haircolor" = 0,
				"race" = 0,
				"skin" = 0,
				"gender" = 0,
				"shape" = "Default Entity",
				"spirit" = "Piou"
			})
			FSM.EnterState(FSM.States.CHAR_PROGRESS)

func SelectCharacter():
	Network.ConnectCharacter(characterNameDisplay.get_text())
	FSM.EnterState(FSM.States.CHAR_PROGRESS)

func UpdateSelectedCharacter(info : Dictionary, slotID : int):
	characterNameDisplay.set_text(info["nickname"])
	Launcher.Camera.EnableSceneCamera(ActorCommons.CharacterScreenLocations[slotID])
	currentCharacterID = slotID

func EnableCharacterCreator(enable : bool):
	isCharacterCreatorEnabled = enable
	statsPanel.set_visible(!enable)
	characterNameDisplay.set_visible(!enable)
	characterNameLineEdit.set_visible(enable)
	traitsPanel.set_visible(enable)
	attributesPanel.set_visible(enable)

	if Launcher.GUI.buttonBoxes:
		Launcher.GUI.buttonBoxes.ClearAll()
		if enable:
			Launcher.GUI.buttonBoxes.SetLeft("Cancel", EnableCharacterCreator.bind(false))
			Launcher.GUI.buttonBoxes.SetMiddle("Randomize", RandomizeCharacter)
			Launcher.GUI.buttonBoxes.SetRight("Create", CreateCharacter)
		else:
			Launcher.GUI.buttonBoxes.SetLeft("Cancel", FSM.EnterState.bind(FSM.States.LOGIN_SCREEN))
			Launcher.GUI.buttonBoxes.SetMiddle("New Player", EnableCharacterCreator.bind(true))
			Launcher.GUI.buttonBoxes.SetRight("Select", SelectCharacter)

func RefreshOnce():
	Launcher.Map.EmplaceMapNode(ActorCommons.CharacterScreenMap)
	Launcher.Camera.SetBoundaries()
	Launcher.Camera.EnableSceneCamera(ActorCommons.CharacterScreenLocations[0])
	EnableCharacterCreator(isCharacterCreatorEnabled)
	Launcher.Map.RemoveChildren()
	for characterID in characters.size():
		characters[characterID] = {}
	currentCharacterID = -1
	Network.CharacterListing()

#
func _ready():
	characters.resize(ActorCommons.MaxCharacterCount)
