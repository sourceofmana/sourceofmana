extends Node

#
var _text = ""
var _delay = 5.0
var _timer = 0.0

#
func OnDisplay(text):
	_text = text
	StartTimer()

func StartTimer():
	_timer = _delay

#
func _process(delta):
	_timer -= delta
	if _timer < 0.0:
		_timer = 0.0
		_text = ""
	print(_text)
