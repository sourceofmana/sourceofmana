extends Control

# Editor variables
@export var textureProgress : Texture2D		= null
@export var textureBackground : Texture2D	= null
@export var labelColor : Color				= Color.WHITE
@export var labelUnit : String				= ""
@export var labelScale : float				= 1.0
@export var labelOffset : Vector2			= Vector2.ZERO
@export var fillDuration : float			= 0.0
@export var initDuration : float			= 0.0
@export var precisionDivider : int			= 0
@export var numberAfterComma : int			= 0
@export var displayMax : bool				= true
@export var displayRatio : bool				= false
@export var fillMode : ProgressBar.FillMode	= ProgressBar.FILL_BEGIN_TO_END

# UI variables
@onready var bar : TextureProgressBar		= $Bar
@onready var label : Label					= $Label

# Internal variables
var tween : Tween							= null
var currentPercent : float					= 0.0
var targetValue : float						= 0.0
var targetMax : float						= 0.0

# Common override
func _ready():
	assert(bar != null, "ProgressBar: Bar node is missing")
	assert(label != null, "ProgressBar: Label node is missing")

	bar.fill_mode = fillMode
	if textureProgress:
		bar.texture_progress = textureProgress
		if anchor_bottom == anchor_top and anchor_left == anchor_right:
			set_deferred("bar.size", textureProgress.get_size())
	if textureBackground:
		bar.texture_under = textureBackground

	if labelScale != 1.0:
		label.set_scale(Vector2(labelScale, labelScale))
		label.position.y -= ceil((1.0 - labelScale) * 10.0)
	if labelColor:
		label.set("theme_override_colors/font_color", labelColor)
	if labelOffset != Vector2.ZERO:
		label.position += labelOffset

# Public setter
func SetUnit(unit : String):
	labelUnit = unit
	displayRatio = unit == "%"
	displayMax = unit != "%"

func SetStat(value : float, maxValue : float):
	assert(bar != null and label != null, "ProgressBar: children are missing")

	var newPercent : float = value / maxValue * 100.0 if maxValue > 0.0 else 0.0
	var duration : float = initDuration if currentPercent == 0.0 else fillDuration

	targetValue = value
	targetMax = maxValue

	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(Animate, currentPercent, newPercent, duration)

# Internal functions
func Animate(percent : float):
	currentPercent = percent
	bar.set_value(percent)
	label.set_text(FormatLabel(percent))

func FormatLabel(percent : float) -> String:
	var displayValue : float = percent / 100.0 * targetMax
	if precisionDivider != 0:
		displayValue = round(displayValue * precisionDivider) / precisionDivider
	else:
		displayValue = round(displayValue)

	var text : String = Util.GetFormatedText(
		"%.2f" % (percent if displayRatio else displayValue),
		numberAfterComma
	)
	if displayMax:
		text += " / " + Util.GetFormatedText(String.num(targetMax), numberAfterComma)
	if labelUnit.length() > 0:
		text += labelUnit
	return text
