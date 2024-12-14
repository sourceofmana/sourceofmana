extends Control

#
@onready var characterName : PanelContainer				= $PlayerName
@onready var characterNameLineEdit : LineEdit			= $PlayerName/MarginContainer/VBoxContainer/Entry
@onready var characterNameDisplay : Label				= $PlayerName/MarginContainer/VBoxContainer/Name

@onready var display : HBoxContainer					= $Display
@onready var traitsPanel : PanelContainer				= $Display/Traits
@onready var attributesPanel : PanelContainer			= $Display/Attributes
@onready var statsPanel : PanelContainer				= $Display/Stats

var isCharacterCreatorEnabled : bool					= false
var charactersInfo : Array[Dictionary]					= []
var charactersNode : Array[Entity]						= []
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

func FillMissingCharacterInfo(info : Dictionary):
	info.get_or_add("nickname", "")
	info.get_or_add("last_timestamp", 1 << 32)

func HasSlot(slotID : int) -> bool:
	return slotID >= 0 and slotID < charactersInfo.size()

func GetDefaultSlot(slotID : int) -> int:
	return slotID if HasSlot(slotID) else 0

func NextAvailableSlot() -> int:
	var availableSlot : int = -1
	for charID in charactersInfo.size():
		if charactersInfo[charID].is_empty():
			availableSlot = charID
			break
	return availableSlot

func AddCharacter(info : Dictionary):
	FillMissingCharacterInfo(info)

	var entity : Entity = Instantiate.CreateEntity(ActorCommons.Type.PLAYER, "Default Entity", info["nickname"], false)
	if not entity:
		assert(false, "Could not create character preview")
		return

	var availableSlot : int = NextAvailableSlot()

	if availableSlot == -1:
		assert(false, "No free available placement")
		return

	charactersInfo[availableSlot] = info
	charactersNode[availableSlot] = entity

	Launcher.Map.AddChild(entity)
	var randDir : Vector2 = Vector2(randf_range(-0.8, 0.8), 1.0)
	var randState : ActorCommons.State = ActorCommons.State.IDLE if isCharacterCreatorEnabled or randi() % 2 == 1 else ActorCommons.State.SIT
	entity.Update(Vector2.ZERO, ActorCommons.CharacterScreenLocations[availableSlot], randDir, randState, -1, true)

	if not HasSlot(currentCharacterID) or \
	"last_timestamp" not in charactersInfo[currentCharacterID] or charactersInfo[currentCharacterID]["last_timestamp"] == null or \
	(info["last_timestamp"] != null and charactersInfo[currentCharacterID]["last_timestamp"] < info["last_timestamp"]):
		UpdateSelectedCharacter(info, availableSlot)

func RemoveCharacter(slotID):
	if HasSlot(slotID):
		if charactersNode[slotID] != null:
			Launcher.Map.RemoveChild(charactersNode[slotID])
			charactersNode[slotID] = null
		if not charactersInfo[slotID].is_empty():
			charactersInfo[slotID] = {}

		if currentCharacterID == slotID:
			var mostRecentTimestamp : int = -1
			var mostRecentCharacterID : int = -1
			for characterID in charactersInfo.size():
				if not charactersInfo[characterID].is_empty():
					if mostRecentCharacterID == -1:
						mostRecentCharacterID = characterID
					elif "last_timestamp" in charactersInfo[characterID] and charactersInfo[characterID]["last_timestamp"] != null and mostRecentTimestamp < charactersInfo[characterID]["last_timestamp"]:
						mostRecentTimestamp = charactersInfo[characterID]["last_timestamp"]
						mostRecentCharacterID = characterID
			UpdateSelectedCharacter(charactersInfo[mostRecentCharacterID] if HasSlot(mostRecentCharacterID) else {}, mostRecentCharacterID)

func RandomizeCharacter():
	attributesPanel.Randomize()

func CreateCharacter():
	if isCharacterCreatorEnabled:
		var nickname : String = characterNameLineEdit.get_text()
		var err : NetworkCommons.CharacterError = NetworkCommons.CheckCharacterInformation(nickname)
		if err != NetworkCommons.CharacterError.ERR_OK:
			FillWarningLabel(err)
		else:
			Network.CreateCharacter(nickname, traitsPanel.GetValues(), attributesPanel.GetValues())
			FSM.EnterState(FSM.States.CHAR_PROGRESS)

func SelectCharacter():
	Network.ConnectCharacter(characterNameDisplay.get_text())
	FSM.EnterState(FSM.States.CHAR_PROGRESS)

func UpdateSelectedCharacter(info : Dictionary = {}, slotID : int = -1):
	if "nickname" in info:
		characterNameDisplay.set_text(info["nickname"])

	var displayInformation : bool = not info.is_empty() or isCharacterCreatorEnabled
	characterName.set_visible(displayInformation)
	display.set_visible(displayInformation)

	Launcher.Camera.EnableSceneCamera(ActorCommons.CharacterScreenLocations[GetDefaultSlot(slotID)])
	currentCharacterID = slotID

func EnableCharacterCreator(enable : bool):
	var wasCharacterCreatorEnabled : bool = isCharacterCreatorEnabled
	isCharacterCreatorEnabled = enable

	if wasCharacterCreatorEnabled:
		if not enable and HasSlot(currentCharacterID) and charactersNode[currentCharacterID] != null:
			RemoveCharacter(currentCharacterID)
	else:
		if enable:
			AddCharacter({})

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
			Launcher.GUI.buttonBoxes.SetLeft("Cancel", Leave)
			if NextAvailableSlot() != -1:
				Launcher.GUI.buttonBoxes.SetMiddle("New Player", EnableCharacterCreator.bind(true))
			Launcher.GUI.buttonBoxes.SetRight("Select", SelectCharacter)

func RefreshOnce():
	Launcher.Map.EmplaceMapNode(ActorCommons.CharacterScreenMap)
	Launcher.Camera.SetBoundaries()

	Launcher.Map.RemoveChildren()
	for slotID in charactersInfo.size():
		RemoveCharacter(slotID)
	currentCharacterID = -1

	EnableCharacterCreator(isCharacterCreatorEnabled)
	UpdateSelectedCharacter({}, currentCharacterID)
	Network.CharacterListing()

func Leave():
	FSM.EnterState(FSM.States.LOGIN_SCREEN)
	for slotID in charactersInfo.size():
		RemoveCharacter(slotID)
	currentCharacterID = -1

#
func _ready():
	charactersInfo.resize(ActorCommons.MaxCharacterCount)
	charactersNode.resize(ActorCommons.MaxCharacterCount)
