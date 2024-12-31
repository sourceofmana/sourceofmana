extends Node
class_name TraitData

@export var _name : String
@export var _path : String

func _init():
	_name = "Unknown"
	_path = ""

static func Create(key : String, path : String) -> TraitData:
	var data : TraitData = TraitData.new()
	data._name = key
	data._path = path

	return data
