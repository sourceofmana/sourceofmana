@tool
extends Object
class_name Destination

@export var mapID : int
@export var pos : Vector2
@export var instance : int

func _init(_mapID : int = DB.UnknownHash, _pos : Vector2 = Vector2.ZERO, _instance : int = 0):
	mapID = _mapID
	pos = _pos
	instance = _instance
