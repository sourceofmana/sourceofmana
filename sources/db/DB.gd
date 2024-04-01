extends Object
class_name DB

static var MapsDB : Dictionary				= {}
static var MusicsDB : Dictionary			= {}
static var EthnicitiesDB : Dictionary		= {}
static var HairstylesDB : Dictionary		= {}
static var EntitiesDB : Dictionary			= {}
static var EmotesDB : Dictionary			= {}
static var ItemsDB : Dictionary				= {}
static var SkillsDB : Dictionary			= {}

#
static func ParseMapsDB():
	var result = FileSystem.LoadDB("maps.json")

	if not result.is_empty():
		for key in result:
			var map : MapData = MapData.new()
			map._name = key
			map._path = result[key].Path
			MapsDB[key] = map

static func ParseMusicsDB():
	var result = FileSystem.LoadDB("musics.json")

	if not result.is_empty():
		for key in result:
			var music : MusicData = MusicData.new()
			music._name = key
			music._path = result[key].Path
			MusicsDB[key] = music

static func ParseEthnicitiesDB():
	var result = FileSystem.LoadDB("ethnicities.json")

	if not result.is_empty():
		for key in result:
			var ethnicity : TraitData = TraitData.new()
			ethnicity._name = key
			ethnicity._path.append(result[key].Male)
			ethnicity._path.append(result[key].Female)
			ethnicity._path.append(result[key].Nonbinary)
			EthnicitiesDB[key] = ethnicity

static func ParseHairstylesDB():
	var result = FileSystem.LoadDB("hairstyles.json")

	if not result.is_empty():
		for key in result:
			var hairstyle : TraitData = TraitData.new()
			hairstyle._name = key
			hairstyle._path.append(result[key].Male)
			hairstyle._path.append(result[key].Female)
			hairstyle._path.append(result[key].Nonbinary)
			HairstylesDB[key] = hairstyle

static func ParseEntitiesDB():
	var result = FileSystem.LoadDB("entities.json")

	if not result.is_empty():
		for key in result:
			EntitiesDB[key] = EntityData.Create(key, result[key])

static func ParseEmotesDB():
	for file in FileSystem.GetFiles(Path.EmotePst):
		var cell : BaseCell = FileSystem.LoadCell(Path.EmotePst + file)
		if cell:
			EmotesDB[cell.name] = cell

static func ParseItemsDB():
	for file in FileSystem.GetFiles(Path.ItemPst):
		var cell : BaseCell = FileSystem.LoadCell(Path.ItemPst + file)
		if cell:
			ItemsDB[cell.name] = cell

static func ParseSkillsDB():
	for file in FileSystem.GetFiles(Path.SkillPst):
		var cell : SkillCell = FileSystem.LoadCell(Path.SkillPst + file)
		if cell:
			SkillsDB[cell.name] = cell

#
static func GetMapPath(mapName : String) -> String:
	var path : String = ""
	var mapInfo = null

	if MapsDB.has(mapName):
		mapInfo = MapsDB[mapName]
		Util.Assert(mapInfo != null, "Could not find the map " + mapName + " within the db")
		if mapInfo:
			path = mapInfo._path
	return path

#
static func Init():
	ParseMapsDB()
	ParseMusicsDB()
	ParseEthnicitiesDB()
	ParseHairstylesDB()
	ParseEmotesDB()
	ParseItemsDB()
	ParseSkillsDB()
	ParseEntitiesDB()
