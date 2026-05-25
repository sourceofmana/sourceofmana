extends Node
class_name UIHighlight

const MaxDuration : float			= 10.0

#
var _target : Control				= null
var _tween : Tween					= null
var _timer : SceneTreeTimer			= null
var _originalModulate : Color		= Color.WHITE

#
func Show(target : Control):
	Clear()
	_target = target
	_originalModulate = target.modulate

	_tween = create_tween().set_loops()
	_tween.tween_property(_target, "modulate", Color(2.0, 1.5, 1.5, 0.2), 0.5)
	_tween.tween_property(_target, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

	_timer = get_tree().create_timer(MaxDuration)
	_timer.timeout.connect(Clear)

func Clear():
	if _tween:
		_tween.kill()
		_tween = null

	if _timer:
		if _timer.timeout.is_connected(Clear):
			_timer.timeout.disconnect(Clear)
		_timer = null

	if _target:
		_target.modulate = _originalModulate
		_target = null
