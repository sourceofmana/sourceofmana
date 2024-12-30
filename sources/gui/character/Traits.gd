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

@onready var ethnicityLabel : Label			= $Margin/VBox/Ethnicity/Name
@onready var ethnicityPrev : Button			= $Margin/VBox/Ethnicity/Previous
@onready var ethnicityNext : Button			= $Margin/VBox/Ethnicity/Next

@onready var skintoneLabel : Label			= $Margin/VBox/SkinTone/Name
@onready var skintonePrev : Button			= $Margin/VBox/SkinTone/Previous
@onready var skintoneNext : Button			= $Margin/VBox/SkinTone/Next

@onready var hairstylesCount : int			= DB.HairstylesDB.size()
@onready var haircolorsCount : int			= DB.HaircolorsDB.size()
@onready var ethnicityCount : int			= DB.EthnicitiesDB.size()

var hairstyleValue : int					= 0
var haircolorValue : int					= 0
var genderValue : int						= 0
var ethnicityValue : int					= 0
var skintoneValue : int						= 0

#
func GetValues():
	return {
		"hairstyle" = hairstyleValue,
		"haircolor" = haircolorValue,
		"ethnicity" = ethnicityValue,
		"skin" = skintoneValue,
		"gender" = genderValue,
		"shape" = "Default Entity",
		"spirit" = "Piou",
	}

# Hairstyle
func RefreshHairstyle():
	var hairstyles : Array = DB.HairstylesDB.keys()
	if hairstyleValue >= 0 and hairstyleValue < hairstylesCount:
		hairstyleLabel.set_text(DB.GetHairstyle(hairstyles[hairstyleValue])._name)

func _on_hairstyle_prev_button():
	hairstyleValue = hairstyleValue - 1 if hairstyleValue > 0 else hairstylesCount - 1
	RefreshHairstyle()

func _on_hairstyle_next_button():
	hairstyleValue = hairstyleValue + 1 if hairstyleValue < hairstylesCount else 0
	RefreshHairstyle()

# Haircolor
func RefreshHaircolor():
	var haircolors : Array = DB.HaircolorsDB.keys()
	if haircolorValue >= 0 and haircolorValue < haircolorsCount:
		haircolorLabel.set_text(DB.GetHaircolor(haircolors[haircolorValue])._name)

func _on_haircolor_prev_button():
	haircolorValue = haircolorValue - 1 if haircolorValue > 0 else haircolorsCount - 1
	RefreshHaircolor()

func _on_haircolor_next_button():
	haircolorValue = haircolorValue + 1 if haircolorValue < haircolorsCount - 1 else 0
	RefreshHaircolor()

#
func Randomize():
	hairstyleValue = randi() % hairstylesCount
	haircolorValue = randi() % haircolorsCount
	RefreshHairstyle()
	RefreshHaircolor()

#
func _ready():
	Randomize()
