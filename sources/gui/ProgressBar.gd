extends Control

export(Texture)			var textureProgress
export(Texture)			var textureBackground
export(Color)			var labelColor
export(String)			var labelUnit
export(float)			var labelScale
export(float)			var delayToFillSec
export(int)				var precisionDivider

onready var label		= get_node("Label")
onready var bar			= get_node("Bar")

var isUpdating			= false
var remainsToFillSec	= 0.0
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

	remainsToFillSec = delayToFillSec
	isUpdating = true
	valueFrom = bar.get_value()
	valueTo = newValue
	valueMax = maxValue

	UpdateValue(0)

func UpdateValue(delta):
	if isUpdating:
		remainsToFillSec -= delta

		var ratioToFinish : float = 0
		if delayToFillSec != 0:
			ratioToFinish = (delayToFillSec - remainsToFillSec) / delayToFillSec
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
			valueFrom = valueTo
#
func _ready():
	assert(bar && label, "ProgressBar childs are missing")

	if bar:
		if textureProgress:
			bar.texture_progress = textureProgress
			bar.rect_size = textureProgress.get_size()
		if textureBackground:
			bar.texture_under = textureBackground
	if label:
		if labelScale != 1:
			label.set_scale(Vector2(labelScale,labelScale))
			label.rect_position.y -= ceil((1 - labelScale) * 10) 
		if labelColor:
			label.add_color_override("font_color", labelColor)

func _process(delta):
	UpdateValue(delta)
