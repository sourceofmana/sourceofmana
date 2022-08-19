extends Node

@export var _name : String
@export var _path : PackedStringArray

func _init():
	_name = "Unknown"
	_path = []
	_path.resize(Launcher.Entities.Trait.Gender.size())
