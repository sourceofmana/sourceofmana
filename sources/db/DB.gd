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

static var hashDB : Dictionary				= {}
const UnknownHash : int						= -1

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
	var result = FileSystem.LoadDB("emotes.json")

	if not result.is_empty():
		for key in result:
			var cell : BaseCell = FileSystem.LoadCell(Path.EmotePst + result[key].Path + Path.RscExt)
			cell.id = SetCellHash(cell.name)
			assert(EmotesDB.has(cell.id) == false, "Duplicated cell in EmotesDB")
			EmotesDB[cell.id] = cell

static func ParseItemsDB():
	var result = FileSystem.LoadDB("items.json")

	if not result.is_empty():
		for key in result:
			var cell : BaseCell = FileSystem.LoadCell(Path.ItemPst + result[key].Path + Path.RscExt)
			cell.id = SetCellHash(cell.name)
			assert(ItemsDB.has(cell.id) == false, "Duplicated cell in ItemsDB")
			ItemsDB[cell.id] = cell

static func ParseSkillsDB():
	var result = FileSystem.LoadDB("skills.json")

	if not result.is_empty():
		for key in result:
			var cell : BaseCell = FileSystem.LoadCell(Path.SkillPst + result[key].Path + Path.RscExt)
			cell.id = SetCellHash(cell.name)
			assert(SkillsDB.has(cell.id) == false, "Duplicated cell in SkillsDB")
			SkillsDB[cell.id] = cell

#
static func GetMapPath(mapName : String) -> String:
	var path : String = ""
	var mapInfo = null

	if MapsDB.has(mapName):
		mapInfo = MapsDB[mapName]
		assert(mapInfo != null, "Could not find the map " + mapName + " within the db")
		if mapInfo:
			path = mapInfo._path
	return path

#
static func HasCellHash(cellname : StringName) -> bool:
	return hashDB.has(cellname)

static func SetCellHash(cellname : StringName) -> int:
	var cellHash : int = UnknownHash
	var hasHash : bool = HasCellHash(cellname)
	assert(not hasHash, "Cell hash %d already exists for %s" % [cellHash, cellname])
	if not hasHash:
		cellHash = cellname.hash()
		hashDB[cellname] = cellHash
	return cellHash

static func GetCellHash(cellname : StringName) -> int:
	var hasHash : bool = HasCellHash(cellname)
	assert(hasHash, "Cell hash already exists for " + cellname)
	return hashDB[cellname] if hasHash else UnknownHash

#
static func GetItem(cellHash : int) -> BaseCell:
	assert(cellHash in ItemsDB, "Could not find the identifier %s in ItemsDB" % [cellHash])
	return ItemsDB[cellHash] if cellHash in ItemsDB else null

static func GetEmote(cellHash : int) -> BaseCell:
	assert(cellHash in EmotesDB, "Could not find the identifier %s in EmotesDB" % [cellHash])
	return EmotesDB[cellHash] if cellHash in EmotesDB else null

static func GetSkill(cellHash : int) -> SkillCell:
	assert(cellHash in SkillsDB, "Could not find the identifier %s in SkillsDB" % [cellHash])
	return SkillsDB[cellHash] if cellHash in SkillsDB else null

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
