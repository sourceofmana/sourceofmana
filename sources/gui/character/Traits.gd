extends PanelContainer

#
@onready var hairstyleLabel : Label			= $Margin/VBox/Hairstyle/Name
@onready var hairstylePrev : Button			= $Margin/VBox/Hairstyle/Previous
@onready var hairstyleNext : Button			= $Margin/VBox/Hairstyle/Next

@onready var haircolorLabel : Label			= $Margin/VBox/HairColor/Name
@onready var haircolorPrev : Button			= $Margin/VBox/HairColor/Previous
@onready var haircolorNext : Button			= $Margin/VBox/HairColor/Next

@onready var genderLabel : Label			= $Margin/VBox/Gender/Name
@onready var genderPrev : Button			= $Margin/VBox/Gender/Previous
@onready var genderNext : Button			= $Margin/VBox/Gender/Next

@onready var raceLabel : Label			= $Margin/VBox/Race/Name
@onready var racePrev : Button			= $Margin/VBox/Race/Previous
@onready var raceNext : Button			= $Margin/VBox/Race/Next

@onready var skintoneLabel : Label			= $Margin/VBox/SkinTone/Name
@onready var skintonePrev : Button			= $Margin/VBox/SkinTone/Previous
@onready var skintoneNext : Button			= $Margin/VBox/SkinTone/Next

@onready var hairstylesCount : int			= DB.HairstylesDB.size()
@onready var haircolorsCount : int			= DB.PalettesDB[DB.Palette.HAIR].size()
@onready var raceCount : int				= DB.RacesDB.size()
var skintoneCount : int						= 0

var hairstyleValue : int					= 0
var haircolorValue : int					= 0
var genderValue : int						= 0
var raceValue : int							= 0
var skintoneValue : int						= 0

signal bodyUpdate
signal hairUpdate

#
func GetValues():
	var hairstyles : PackedInt64Array = DB.HairstylesDB.keys()
	var haircolors : PackedInt64Array = DB.PalettesDB[DB.Palette.HAIR].keys()
	var races : PackedInt64Array = DB.RacesDB.keys()
	var race : RaceData = DB.GetRace(races[raceValue])
	var skins : Dictionary[int, FileData] = race._skins if race else {}
	var skinsKeys : PackedInt64Array = skins.keys()

	return {
		"hairstyle" = hairstyles[hairstyleValue],
		"haircolor" = haircolors[haircolorValue],
		"race" = races[raceValue],
		"skintone" = skinsKeys[skintoneValue],
		"gender" = genderValue
	}

# Hairstyle
func RefreshHairstyle():
	var hairstyles : PackedInt64Array = DB.HairstylesDB.keys()
	if hairstyleValue >= 0 and hairstyleValue < hairstylesCount:
		hairstyleLabel.set_text(DB.GetHairstyle(hairstyles[hairstyleValue])._name)
		hairUpdate.emit()

func _on_hairstyle_prev_button():
	hairstyleValue = hairstyleValue - 1 if hairstyleValue > 0 else hairstylesCount - 1
	RefreshHairstyle()

func _on_hairstyle_next_button():
	hairstyleValue = hairstyleValue + 1 if hairstyleValue < hairstylesCount - 1 else 0
	RefreshHairstyle()

# Haircolor
func RefreshHaircolor():
	var palettes : PackedInt64Array = DB.PalettesDB[DB.Palette.HAIR].keys()
	if haircolorValue >= 0 and haircolorValue < haircolorsCount:
		haircolorLabel.set_text(DB.GetPalette(DB.Palette.HAIR, palettes[haircolorValue])._name)
		hairUpdate.emit()

func _on_haircolor_prev_button():
	haircolorValue = haircolorValue - 1 if haircolorValue > 0 else haircolorsCount - 1
	RefreshHaircolor()

func _on_haircolor_next_button():
	haircolorValue = haircolorValue + 1 if haircolorValue < haircolorsCount - 1 else 0
	RefreshHaircolor()

# Gender
func RefreshGender():
	genderLabel.set_text(ActorCommons.GetGenderName(genderValue))
	bodyUpdate.emit()

func _on_gender_prev_button():
	genderValue = genderValue - 1 if genderValue > 0 else ActorCommons.Gender.COUNT - 1
	RefreshGender()

func _on_gender_next_button():
	genderValue = genderValue + 1 if genderValue < ActorCommons.Gender.COUNT - 1 else 0
	RefreshGender()

# Race
func RefreshRace():
	var races : PackedInt64Array = DB.RacesDB.keys()
	if raceValue >= 0 and raceValue < raceCount:
		var data : RaceData = DB.GetRace(races[raceValue])
		raceLabel.set_text(data._name)
		RefreshSkintone()
		bodyUpdate.emit()

func _on_race_prev_button():
	raceValue = raceValue - 1 if raceValue > 0 else raceCount - 1
	RefreshRace()

func _on_race_next_button():
	raceValue = raceValue + 1 if raceValue < raceCount - 1 else 0
	RefreshRace()

# Skin tone
func RefreshSkintone():
	var races : PackedInt64Array = DB.RacesDB.keys()
	if raceValue >= 0 and raceValue < raceCount:
		var data : RaceData = DB.GetRace(races[raceValue])
		var skins : Dictionary[int, FileData] = data._skins
		var skinsKeys : PackedInt64Array = skins.keys()
		skintoneCount = data._skins.size()
		if skintoneValue < 0 or skintoneValue >= skintoneCount:
			skintoneValue = 0
		if skintoneValue >= 0 and skintoneValue < skintoneCount:
			skintoneLabel.set_text(skins[skinsKeys[skintoneValue]]._name)
			bodyUpdate.emit()

func _on_skintone_prev_button():
	skintoneValue = skintoneValue - 1 if skintoneValue > 0 else skintoneCount - 1
	RefreshSkintone()

func _on_skintone_next_button():
	skintoneValue = skintoneValue + 1 if skintoneValue < skintoneCount - 1 else 0
	RefreshSkintone()

#
func Randomize():
	hairstyleValue = randi() % hairstylesCount
	RefreshHairstyle()
	haircolorValue = randi() % haircolorsCount
	RefreshHaircolor()
	genderValue = randi() % ActorCommons.Gender.COUNT
	RefreshGender()
	raceValue = randi() % raceCount
	RefreshRace()
	skintoneValue = randi() % skintoneCount
	RefreshSkintone()

#
func _ready():
	Randomize()
