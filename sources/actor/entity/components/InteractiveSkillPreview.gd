extends Control

#
const mainColor : Color		= Color("99680599")
const outerColor : Color	= Color("D7B77BFF")
const tweenDuration : float	= 0.4

var displayRange : float	= -1.0
var currentAlpha : float	= 0.0 :
	set(value):
		currentAlpha = value
		queue_redraw()
var tween: Tween			= null

#
func Display(_displayRange : float):
	ResetTween()

	displayRange = _displayRange
	visible = true

	tween = create_tween()
	tween.tween_property(self, "currentAlpha", 1.0, tweenDuration)
	tween.tween_callback(queue_redraw)

func Hide():
	ResetTween()

	visible = false
	displayRange = -1.0
	currentAlpha = 0.0

	queue_redraw()

func ResetTween():
	if tween and tween.is_running():
		tween.kill()

#
func _draw():
	if displayRange > 2.0:
		draw_arc(Vector2.ZERO, displayRange - 1, 0, TAU, 64, Color(outerColor, currentAlpha), 1.0)
		draw_arc(Vector2.ZERO, displayRange, 0, TAU, 64, Color(mainColor, currentAlpha), 1.0)
		draw_arc(Vector2.ZERO, displayRange + 1, 0, TAU, 64, Color(outerColor, currentAlpha), 1.0)
