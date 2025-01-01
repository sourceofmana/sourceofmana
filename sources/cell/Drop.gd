extends Node2D
class_name Drop

var item : Item				= null
var timer : Timer			= null

func _init(_item : Item, _pos : Vector2):
	item = _item
	position = _pos
