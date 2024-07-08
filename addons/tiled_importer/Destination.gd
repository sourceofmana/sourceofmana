@tool
extends Object
class_name Destination

@export var map : String
@export var pos : Vector2

func _init(_map : String = "", _pos : Vector2 = Vector2.ZERO):
	map = _map
	pos = _pos
