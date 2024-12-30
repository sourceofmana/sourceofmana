extends Node
class_name TraitData

@export var _name : String
@export var _path : PackedStringArray

func _init():
	_name = "Unknown"
	_path = []

static func Create(key : String, result : Variant) -> TraitData:
	var data : TraitData = TraitData.new()
	data._name = key
	if result is String:
		data._path.append(result)
	elif result is Dictionary:
		if "Male" in result:
			data._path.append(result.Male)
		if "Female" in result:
			data._path.append(result.Female)
		if "Nonbinary" in result:
			data._path.append(result.Nonbinary)
		assert(not data._path.is_empty(), "No path found for the race " + key)

	return data
