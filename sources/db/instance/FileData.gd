extends Resource
class_name FileData

@export var _id : int				= DB.UnknownHash
@export var _name : String			= ""
@export var _resource : Resource	= null

#
static func Create(key : String, resource : Resource) -> FileData:
	var data : FileData = FileData.new()
	data._id = key.hash()
	data._name = key
	data._resource = resource

	return data
