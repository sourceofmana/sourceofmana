extends Node
class_name RaceData

@export var _name : String				= "Unknown"
@export var _heads : Array[String]		= []
@export var _bodies : Array[String]		= []
@export var _skins : Dictionary			= {}

func _init():
	_heads.resize(ActorCommons.Gender.COUNT)
	_bodies.resize(ActorCommons.Gender.COUNT)

static func Create(key : String, result : Dictionary) -> RaceData:
	var data : RaceData = RaceData.new()
	data._name = key
	if "Bodies" in result and result.Bodies is Dictionary:
		for gender in ActorCommons.Gender.COUNT:
			data._bodies[gender] = result.Bodies.get(ActorCommons.GetGenderName(gender), "")
	if "Heads" in result and result.Heads is Dictionary:
		for gender in ActorCommons.Gender.COUNT:
			data._heads[gender] = result.Heads.get(ActorCommons.GetGenderName(gender), "")
	if "Skins" in result and result.Skins is Dictionary:
		for skin in result.Skins.keys():
			var id = DB.GetCellHash(skin) if DB.HasCellHash(skin) else DB.SetCellHash(skin)
			assert(id not in data._skins, "Duplicated skin ID in %s" % key)
			data._skins[id] = TraitData.Create(skin, result.Skins[skin])

	return data
