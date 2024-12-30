extends Node
class_name EthnicityData

@export var _name : String				= "Unknown"
@export var _preset : String			= ""
@export var _malePath : String			= ""
@export var _femalePath : String		= ""
@export var _nonbinaryPath : String		= ""
@export var _skins : Dictionary			= {}

static func Create(key : String, result : Dictionary) -> EthnicityData:
	var data : EthnicityData = EthnicityData.new()
	data._name = key
	data._preset = result.Preset
	if "Male" in result:
		data._malePath = result.Male
	if "Female" in result:
		data._femalePath = result.Female
	if "Nonbinary" in result:
		data._nonbinaryPath = result.Nonbinary
	if "Skins" in result and result.Skins is Dictionary:
		for skin in result.Skins.keys():
			data._skins[skin] = result.Skins[skin]

	return data
