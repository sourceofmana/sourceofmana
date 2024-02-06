extends ServiceBase

var MapsDB : Dictionary				= {}
var MusicsDB : Dictionary			= {}
var EthnicitiesDB : Dictionary		= {}
var HairstylesDB : Dictionary		= {}
var EntitiesDB : Dictionary			= {}
var EmotesDB : Dictionary			= {}
var SkillsDB : Dictionary			= {}

#
func ParseMapsDB():
	var result = FileSystem.LoadDB("maps.json")

	if not result.is_empty():
		for key in result:
			var map : MapData = MapData.new()
			map._name = key
			map._path = result[key].Path
			MapsDB[key] = map

func ParseMusicsDB():
	var result = FileSystem.LoadDB("musics.json")

	if not result.is_empty():
		for key in result:
			var music : MusicData = MusicData.new()
			music._name = key
			music._path = result[key].Path
			MusicsDB[key] = music

func ParseEthnicitiesDB():
	var result = FileSystem.LoadDB("ethnicities.json")

	if not result.is_empty():
		for key in result:
			var ethnicity : TraitData = TraitData.new()
			ethnicity._name = key
			ethnicity._path.append(result[key].Male)
			ethnicity._path.append(result[key].Female)
			ethnicity._path.append(result[key].Nonbinary)
			EthnicitiesDB[key] = ethnicity

func ParseHairstylesDB():
	var result = FileSystem.LoadDB("hairstyles.json")

	if not result.is_empty():
		for key in result:
			var hairstyle : TraitData = TraitData.new()
			hairstyle._name = key
			hairstyle._path.append(result[key].Male)
			hairstyle._path.append(result[key].Female)
			hairstyle._path.append(result[key].Nonbinary)
			HairstylesDB[key] = hairstyle

func ParseEntitiesDB():
	var result = FileSystem.LoadDB("entities.json")

	if not result.is_empty():
		for key in result:
			EntitiesDB[key] = EntityData.Create(key, result[key])

#
func ParseEmotesDB():
	var result = FileSystem.LoadDB("emotes.json")

	if not result.is_empty():
		for key in result:
			var emote : EmoteData = EmoteData.new()
			emote._id = key.to_int()
			emote._name = result[key].Name
			emote._path = result[key].Path
			EmotesDB[key] = emote

#
func ParseSkillsDB():
	var result = FileSystem.LoadDB("skills.json")

	if not result.is_empty():
		for key in result:
			SkillsDB[key] = SkillData.Create(key, result[key])

#
func GetMapPath(mapName : String) -> String:
	var path : String = ""
	var mapInfo = null

	if MapsDB.has(mapName):
		mapInfo = MapsDB[mapName]
		Util.Assert(mapInfo != null, "Could not find the map " + mapName + " within the db")
		if mapInfo:
			path = mapInfo._path
	return path

#
func _post_launch():
	ParseMapsDB()
	ParseMusicsDB()
	ParseEthnicitiesDB()
	ParseHairstylesDB()
	ParseSkillsDB()
	ParseEntitiesDB()
	ParseEmotesDB()


	isInitialized = true
