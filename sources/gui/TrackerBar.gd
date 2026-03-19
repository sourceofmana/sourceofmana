extends Control
class_name TrackerBar

#
@onready var label : Label				= $MarginContainer/VBoxContainer/Label
@onready var bar : Control				= $MarginContainer/VBoxContainer/Bar

var tween : Tween						= null

# Accessors
func Display(text : String, value : int, maxValue : int, unit : String = ""):
	label.text = text
	bar.SetUnit(unit)
	bar.SetStat(value, maxValue)
	if not is_visible() or modulate.a < 1.0:
		FadeIn()

func Clear():
	if is_visible():
		FadeOut()

# Visibility
func FadeIn():
	if tween:
		tween.kill()
	modulate.a = 0.0
	show()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func FadeOut():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(hide)
