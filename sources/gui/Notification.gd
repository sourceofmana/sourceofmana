extends Control

@export var openSpeed : float	= 4.0
@export var closeSpeed : float	= 1.5

@onready var clip : Control			= $ClipContainer
@onready var label : RichTextLabel	= $ClipContainer/Label
@onready var timer : Timer			= $Timer

const HALF_WIDTH : float = 250.0
var tween : Tween = null

#
func _get_minimum_size() -> Vector2:
	if label == null:
		return Vector2.ZERO
	return Vector2(HALF_WIDTH * 2.0, label.get_minimum_size().y)

#
func AddNotification(notif : String, delay : float = 5.0):
	if notif.length() > 0 and delay > 0.0:
		if not timer.is_stopped():
			timer.stop()
		show()
		label.text = "[center]%s[/center]" % notif
		update_minimum_size()
		timer.start(delay)
		Animate(1.0, openSpeed)

func ClearNotification():
	if not timer.is_stopped():
		timer.stop()
	Animate(0.0, closeSpeed)

#
func Animate(target : float, speed : float) -> void:
	if tween:
		tween.kill()
	var current_half : float = clip.offset_right
	var target_half : float = HALF_WIDTH * target
	var duration : float = absf(target_half - current_half) / (HALF_WIDTH * speed)
	tween = create_tween()
	tween.tween_method(
		func(v : float):
			clip.offset_left = -v
			clip.offset_right = v,
		current_half, target_half, duration
	)
	if target == 0.0:
		tween.tween_callback(hide)

#
func _on_timer_timeout():
	ClearNotification()

#
func _ready():
	clip.offset_left = 0.0
	clip.offset_right = 0.0
