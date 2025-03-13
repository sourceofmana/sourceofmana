extends Resource
class_name FileData

@export var _id : int				= DB.UnknownHash
@export var _name : String			= ""
@export var _path : String			= ""

#
static func Create(key : String, path : String) -> FileData:
	var data : FileData = FileData.new()
	data._id = key.hash()
	data._name = key
	data._path = path

	return data
