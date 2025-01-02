extends Node
class_name RaceData

@export var _name : String				= "Unknown"
@export var _malePath : String			= ""
@export var _femalePath : String		= ""
@export var _nonbinaryPath : String		= ""
@export var _skins : Dictionary			= {}

static func Create(key : String, result : Dictionary) -> RaceData:
	var data : RaceData = RaceData.new()
	data._name = key
	if "Male" in result:
		data._malePath = result.Male
	if "Female" in result:
		data._femalePath = result.Female
	if "Nonbinary" in result:
		data._nonbinaryPath = result.Nonbinary
	if "Skins" in result and result.Skins is Dictionary:
		for skin in result.Skins.keys():
			var id = DB.SetCellHash(skin)
			assert(id not in data._skins, "Duplicated skin ID in %s" % key)
			data._skins[id] = TraitData.Create(skin, result.Skins[skin])

	return data
