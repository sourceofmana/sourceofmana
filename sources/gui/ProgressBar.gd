extends Control

@export var textureProgress : Texture2D
@export var textureBackground : Texture2D
@export var labelColor : Color
@export var labelUnit : String
@export var labelScale : float
@export var labelOffset : Vector2
@export var delayToFillSec : float
@export var delayToInitSec : float
@export var precisionDivider : int
@export var numberAfterComma : int
@export var displayMax : bool					= true
@export var displayRatio : bool					= false
@export var fillMode : ProgressBar.FillMode		= ProgressBar.FILL_BEGIN_TO_END

@onready var bar : TextureProgressBar			= $Bar
@onready var label : Label						= $Label

var isUpdating : bool							= false
var remainsToFillSec : float					= 0.0
var initDelayToFillSec : float					= 0.0
var valueFrom : float							= 0.0
var valueTo : float								= 0.0
var valueMax : float							= 0.0
var valueTmp : float							= 0.0

#
func GetRatio(currentValue : float, maxValue : float) -> float:
	var ratio : float = 0.0
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

	commaLocation = value.find(".")
	if commaLocation == -1:
		commaLocation = value.length()
		if numberAfterComma > 0:
			value += "."

	if numberAfterComma > 0:
		for i in range(value.length() - 1, commaLocation + numberAfterComma):
			value += "0"
	else:
		value = value.substr(0, commaLocation)

	return value

func GetBarFormat(currentValue : float, maxValue : float) -> String:
	var formatedText : String = GetFormatedText("%.2f" % ((currentValue / maxValue * 100.0) if displayRatio else currentValue))

	if displayMax:
		var maxValueText : String = GetFormatedText(String.num(maxValue))
		formatedText += " / " + maxValueText

	if labelUnit.length() > 0.0:
		formatedText += labelUnit

	return formatedText

#
func SetStat(newValue : float, maxValue : float):
	Util.Assert(bar != null && label != null, "ProgressBar childs are missing")
	if valueTo != newValue || valueMax != maxValue:
		var previousValue : float = valueTo

		valueTo = newValue
		valueMax = maxValue
		if not isUpdating:
			isUpdating = true
			valueFrom = previousValue

			if valueFrom == 0.0:
				remainsToFillSec = delayToInitSec
				initDelayToFillSec = delayToInitSec
			else:
				remainsToFillSec = delayToFillSec
				initDelayToFillSec = delayToFillSec

			_physics_process(0.0)

#
func _ready():
	Util.Assert(bar != null, "ProgressBar bar child is missing")
	if bar:
		bar.fill_mode = fillMode
		if textureProgress:
			bar.texture_progress = textureProgress
			if anchor_bottom == anchor_top && anchor_left == anchor_right:
				set_deferred("bar.size", textureProgress.get_size())
		if textureBackground:
			bar.texture_under = textureBackground

	Util.Assert(label != null, "ProgressBar label child is missing")
	if label:
		if labelScale != 1:
			label.set_scale(Vector2(labelScale,labelScale))
			label.position.y -= ceil((1 - labelScale) * 10) 
		if labelColor:
			label.set("theme_override_colors/font_color", labelColor)
		if labelOffset != Vector2.ZERO:
			label.position += labelOffset

func _physics_process(delta : float):
	if isUpdating:
		remainsToFillSec -= delta

		var ratioToFinish : float = 0.0
		if initDelayToFillSec != 0:
			ratioToFinish = (initDelayToFillSec - remainsToFillSec) / initDelayToFillSec
			ratioToFinish = ease(ratioToFinish, 0.3)

		valueTmp = lerpf(valueFrom, valueTo, ratioToFinish)
		if bar:
			bar.set_value(GetRatio(valueTmp, valueMax))

		if precisionDivider != 0:
			valueTmp = round(valueTmp * precisionDivider) / precisionDivider
		else:
			valueTmp = round(valueTmp)

		if label:
			label.set_text(GetBarFormat(valueTmp, valueMax))

		if valueFrom == valueTo || remainsToFillSec <= 0:
			if bar:
				bar.set_value(GetRatio(valueTo, valueMax))
			if label:
				label.set_text(GetBarFormat(valueTo, valueMax))
			
			isUpdating = false
			remainsToFillSec = 0
			initDelayToFillSec = 0
			valueFrom = valueTo
