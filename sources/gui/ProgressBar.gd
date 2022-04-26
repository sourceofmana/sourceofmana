extends Control

export(Texture)		var textureProgress
export(Color)		var labelColor
export(float)		var labelScale

onready var label	= get_node("Label")
onready var bar		= get_node("Bar")

#
func GetRatio(currentValue : int, maxValue : int) -> float:
	var ratio = 0.0
	if maxValue > 0:
		ratio = float(currentValue) / maxValue * 100
	return ratio

func GetFormatedText(value : String) -> String:
	var i : int = value.length() - 3
	while i > 0:
		value = value.insert(i, ",")
		i = i - 3
	return value

func GetBarFormat(currentValue : int, maxValue : int) -> String:
	var currentValueText = GetFormatedText(currentValue as String)
	var maxValueText = GetFormatedText(maxValue as String)
	return currentValueText + " / " + maxValueText

#
func SetStat(currentValue, maxValue):
	assert(bar && label, "ProgressBar childs are missing")

	if bar:
		bar.set_value(GetRatio(currentValue, maxValue))
	if label:
		label.set_text(GetBarFormat(currentValue, maxValue))

#
func _ready():
	assert(bar && label, "ProgressBar childs are missing")

	if bar:
		if textureProgress:
			bar.texture_progress = textureProgress
			bar.rect_size = textureProgress.get_size()
	if label:
		if labelScale != 1:
			label.set_scale(Vector2(labelScale,labelScale))
			label.rect_position.y -= ceil((1 - labelScale) * 10) 
		if labelColor:
			label.add_color_override("font_color", labelColor)

func _process(_delta):
	pass
