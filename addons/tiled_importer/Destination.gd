@tool
extends Object
class_name Destination

@export var map : String
@export var pos : Vector2
@export var instance : int

func _init(_map : String = "", _pos : Vector2 = Vector2.ZERO, _instance : int = 0):
	map = _map
	pos = _pos
	instance = _instance
