extends Control

@export var textureProgress : Texture2D
@export var textureBackground : Texture2D
@export var labelColor : Color
@export var labelUnit : String
@export var labelScale : float
@export var delayToFillSec : float
@export var delayToInitSec : float
@export var precisionDivider : int

@onready var label		= get_node("Label")
@onready var bar		= get_node("Bar")

var isUpdating			= false
var remainsToFillSec	= 0.0
var initDelayToFillSec	= 0.0
var valueFrom			= 0
var valueTo				= 0
var valueMax			= 0

#
func GetRatio(currentValue : float, maxValue : float) -> float:
	var ratio = 0.0
	if maxValue > 0:
		ratio = currentValue / maxValue * 100.0
	return ratio

func GetFormatedText(value : String) -> String:
	var commaLocation : int = value.find(".")
	var charCounter : int = 0

	if commaLocation > 0:
		charCounter = commaLocation - 3
	else:
		charCounter = value.length() - 3

	while charCounter > 0:
		value = value.insert(charCounter, ",")
		charCounter = charCounter - 3
	return value

func GetBarFormat(currentValue : float, maxValue : float) -> String:
	var currentValueText = GetFormatedText(currentValue as String)
	var maxValueText = GetFormatedText(maxValue as String)

	var formatedText = currentValueText + " / " + maxValueText
	if labelUnit.length() > 0:
		formatedText += " " + labelUnit
	
	return formatedText

#
func SetStat(newValue, maxValue):
	assert(bar && label, "ProgressBar childs are missing")

	valueFrom = bar.get_value()
	valueTo = newValue
	isUpdating = true
	valueMax = maxValue
	if valueFrom == 0:
		remainsToFillSec = delayToInitSec
		initDelayToFillSec = delayToInitSec
	else:
		remainsToFillSec = delayToFillSec
		initDelayToFillSec = delayToFillSec

	UpdateValue(0)

func UpdateValue(delta):
	if isUpdating:
		remainsToFillSec -= delta

		var ratioToFinish : float = 0
		if initDelayToFillSec != 0:
			ratioToFinish = (initDelayToFillSec - remainsToFillSec) / initDelayToFillSec
			ratioToFinish = ease(ratioToFinish, 0.3)

		var newValue = lerp(valueFrom, valueTo, ratioToFinish)
		if bar:
			bar.set_value(GetRatio(newValue, valueMax))

		if precisionDivider != 0:
			newValue = round(newValue * precisionDivider) / precisionDivider
		else:
			newValue = round(newValue)

		if label:
			label.set_text(GetBarFormat(newValue, valueMax))

		if valueFrom == valueTo || remainsToFillSec <= 0:
			if bar:
				bar.set_value(GetRatio(valueTo, valueMax))
			if label:
				label.set_text(GetBarFormat(valueTo, valueMax))
			
			isUpdating = false
			remainsToFillSec = 0
			initDelayToFillSec = 0
			valueFrom = valueTo
#
func _ready():
	assert(bar && label, "ProgressBar childs are missing")

	if bar:
		if textureProgress:
			bar.texture_progress = textureProgress
			bar.size = textureProgress.get_size()
		if textureBackground:
			bar.texture_under = textureBackground
	if label:
		if labelScale != 1:
			label.set_scale(Vector2(labelScale,labelScale))
			label.position.y -= ceil((1 - labelScale) * 10) 
		if labelColor:
			label.set("custom_colors/font_color", labelColor)

func _process(delta):
	UpdateValue(delta)
