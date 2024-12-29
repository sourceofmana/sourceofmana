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
var currentCharacterID : int							= ActorCommons.InvalidCharacterSlot

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
	Util.DicCheckOrAdd(info, "nickname", "")
	Util.DicCheckOrAdd(info, "last_timestamp", 1 << 32)
	Util.DicCheckOrAdd(info, "level", 1)
	Util.DicCheckOrAdd(info, "pos_map", LauncherCommons.DefaultStartMap)

func HasSlot(slotID : int) -> bool:
	return slotID >= 0 and slotID <= ActorCommons.MaxCharacterCount

func GetDefaultSlot(slotID : int) -> int:
	return slotID if HasSlot(slotID) else 0

func NextAvailableSlot() -> int:
	var availableSlot : int = ActorCommons.InvalidCharacterSlot
	for charID in ActorCommons.MaxCharacterCount:
		if charactersInfo[charID].is_empty():
			availableSlot = charID
			break
	return availableSlot

func AddCharacter(info : Dictionary, slotID : int = ActorCommons.InvalidCharacterSlot):
	FillMissingCharacterInfo(info)

	var availableSlot : int = NextAvailableSlot() if slotID == ActorCommons.InvalidCharacterSlot else slotID
	if availableSlot == ActorCommons.InvalidCharacterSlot:
		assert(false, "No free available placement")
		return

	var entity : Entity = Instantiate.CreateEntity(ActorCommons.Type.PLAYER, "Default Entity", info["nickname"], false)
	if not entity:
		assert(false, "Could not create character preview")
		return

	RemoveCharacter(availableSlot)
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

	RefreshCharacterList()

func RemoveCharacter(slotID : int):
	if HasSlot(slotID):
		if charactersNode[slotID] != null:
			Launcher.Map.RemoveChild(charactersNode[slotID])
			charactersNode[slotID] = null
		if not charactersInfo[slotID].is_empty():
			charactersInfo[slotID] = {}

		if currentCharacterID == slotID:
			var mostRecentTimestamp : int = -1
			var mostRecentCharacterID : int = ActorCommons.InvalidCharacterSlot
			for characterID in ActorCommons.MaxCharacterCount:
				if not charactersInfo[characterID].is_empty():
					if mostRecentCharacterID == ActorCommons.InvalidCharacterSlot:
						mostRecentCharacterID = characterID
					elif "last_timestamp" in charactersInfo[characterID] and charactersInfo[characterID]["last_timestamp"] != null and mostRecentTimestamp < charactersInfo[characterID]["last_timestamp"]:
						mostRecentTimestamp = charactersInfo[characterID]["last_timestamp"]
						mostRecentCharacterID = characterID
			UpdateSelectedCharacter(charactersInfo[mostRecentCharacterID] if HasSlot(mostRecentCharacterID) else {}, mostRecentCharacterID)

		RefreshCharacterList()

func RandomizeCharacter():
	attributesPanel.Randomize()

func RefreshCharacterList():
	var characterCount : int = 0
	for character in charactersNode:
		if character != null:
			characterCount += 1
	statsPanel.selection.set_visible(characterCount >= 2)

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

func UpdateSelectedCharacter(info : Dictionary, slotID : int):
	var displayInformation : bool = not info.is_empty() or isCharacterCreatorEnabled
	characterName.set_visible(displayInformation)
	display.set_visible(displayInformation)

	if not isCharacterCreatorEnabled and not info.is_empty():
		statsPanel.SetInfo(info)
		characterNameDisplay.set_text(info["nickname"])

	if HasSlot(slotID) and charactersNode[slotID] != null:
		if HasSlot(currentCharacterID) and charactersNode[currentCharacterID]:
			EnableCharacterSelectionFx(false, currentCharacterID)
		EnableCharacterSelectionFx(true, slotID)

	Launcher.Camera.EnableSceneCamera(ActorCommons.CharacterScreenLocations[GetDefaultSlot(slotID)])
	currentCharacterID = slotID

func EnableCharacterSelectionFx(isEnabled : bool, slotID : int):
	if charactersNode[slotID].interactive:
		charactersNode[slotID].interactive.DisplayTarget(ActorCommons.Target.ALLY if isEnabled else ActorCommons.Target.NONE)
	else:
		charactersNode[slotID].ready.connect(EnableCharacterSelectionFx.bind(isEnabled, slotID))

func ChangeSelectedCharacter(changeClockwise : bool = true):
	if not HasSlot(currentCharacterID):
		currentCharacterID = 0
	var operationValue : int = 1 if changeClockwise else -1

	for slotID in range(1, ActorCommons.MaxCharacterCount):
		var lookupID : int = (currentCharacterID + (slotID * operationValue) + ActorCommons.MaxCharacterCount) % ActorCommons.MaxCharacterCount
		var info : Dictionary = charactersInfo[lookupID]
		if not info.is_empty():
			UpdateSelectedCharacter(info, lookupID)
			break

func EnableCharacterCreator(enable : bool):
	if isCharacterCreatorEnabled != enable:
		var wasCharacterCreatorEnabled : bool = isCharacterCreatorEnabled
		isCharacterCreatorEnabled = enable

		if wasCharacterCreatorEnabled:
			if not enable and HasSlot(currentCharacterID) and charactersNode[currentCharacterID] != null:
				RemoveCharacter(ActorCommons.MaxCharacterCount)
		else:
			if enable:
				AddCharacter({}, ActorCommons.MaxCharacterCount)

	statsPanel.set_visible(not enable)
	characterNameDisplay.set_visible(not enable)
	characterNameLineEdit.set_visible(enable)
	traitsPanel.set_visible(enable)
	attributesPanel.set_visible(enable)

	if Launcher.GUI.buttonBoxes:
		Launcher.GUI.buttonBoxes.ClearAll()
		if enable:
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Create", CreateCharacter)
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.SECONDARY, "Randomize", RandomizeCharacter)
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "Cancel", EnableCharacterCreator.bind(false))
		else:
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "Select", SelectCharacter)
			if NextAvailableSlot() != ActorCommons.InvalidCharacterSlot:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.SECONDARY, "New Player", EnableCharacterCreator.bind(true))
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "Cancel", Leave)

func RefreshOnce():
	if isCharacterCreatorEnabled:
		return

	Launcher.Map.EmplaceMapNode(ActorCommons.CharacterScreenMap)
	Launcher.Camera.SetBoundaries()
	currentCharacterID = ActorCommons.InvalidCharacterSlot
	for slotID in charactersInfo.size():
		RemoveCharacter(slotID)

	EnableCharacterCreator(isCharacterCreatorEnabled)
	UpdateSelectedCharacter({}, currentCharacterID)
	Network.CharacterListing()

func Leave():
	FSM.EnterState(FSM.States.LOGIN_SCREEN)
	for slotID in charactersInfo.size():
		RemoveCharacter(slotID)
	Launcher.GUI.buttonBoxes.ClearAll()
	currentCharacterID = ActorCommons.InvalidCharacterSlot

func Close():
	if isCharacterCreatorEnabled:
		EnableCharacterCreator(false)
	else:
		Leave()

#
func _ready():
	charactersInfo.resize(ActorCommons.MaxCharacterCount + 1)
	charactersNode.resize(ActorCommons.MaxCharacterCount + 1)
	assert(charactersInfo.size() == ActorCommons.CharacterScreenLocations.size(), "Character screen locations count mismatch with the max character count")
	assert(charactersNode.size() == ActorCommons.CharacterScreenLocations.size(), "Character screen locations count mismatch with the max character count")
	statsPanel.previousButton.pressed.connect(ChangeSelectedCharacter.bind(false))
	statsPanel.nextButton.pressed.connect(ChangeSelectedCharacter.bind(true))

func _on_visibility_changed():
	if not visible:
		statsPanel.set_visible(false)
		traitsPanel.set_visible(false)
		attributesPanel.set_visible(false)
