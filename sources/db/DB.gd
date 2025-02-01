extends Object
class_name DB

static var MapsDB : Dictionary				= {}
static var MusicsDB : Dictionary			= {}
static var RacesDB : Dictionary				= {}
static var HairstylesDB : Dictionary		= {}
static var PalettesDB : Array[Dictionary]	= []
static var EntitiesDB : Dictionary			= {}
static var EmotesDB : Dictionary			= {}
static var ItemsDB : Dictionary				= {}
static var SkillsDB : Dictionary			= {}

static var hashDB : Dictionary				= {}
const UnknownHash : int						= -1

enum Palette
{
	HAIR = 0,
	SKIN,
	EQUIPMENT,
	COUNT
}

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

static func ParseRacesDB():
	var result = FileSystem.LoadDB("races.json")

	if not result.is_empty():
		for key in result:
			var id = SetCellHash(key)
			assert(id not in RacesDB, "Duplicated cell in RacesDB")
			RacesDB[id] = RaceData.Create(key, result[key])

static func ParseHairstylesDB():
	var result : Dictionary = FileSystem.LoadDB("hairstyles.json")

	if not result.is_empty():
		for key in result:
			var id = SetCellHash(key)
			assert(id not in HairstylesDB, "Duplicated cell in HairstylesDB")
			HairstylesDB[id] = TraitData.Create(key, result[key])

static func ParsePalettesDB():
	PalettesDB.resize(Palette.COUNT)
	var result : Dictionary = FileSystem.LoadDB("palettes.json")

	if not result.is_empty():
		for categoryKey in result:
			var category : Dictionary = result[categoryKey]
			var categoryIdx : int = int(categoryKey)
			for key in category:
				var id = SetCellHash(key)
				assert(id not in HairstylesDB, "Duplicated cell in PalettesDB")
				PalettesDB[categoryIdx][id] = TraitData.Create(key, category[key])

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
			var cell : ItemCell = FileSystem.LoadCell(Path.ItemPst + result[key].Path + Path.RscExt)
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
static func GetItem(cellHash : int, customfield : String = "") -> ItemCell:
	var hasInDB : bool = cellHash in ItemsDB
	assert(hasInDB, "Could not find the identifier %s in ItemsDB" % [cellHash])
	var cell : ItemCell = ItemsDB[cellHash] if hasInDB else null
	if cell and not customfield.is_empty():
		var customCell = cell.duplicate()
		customCell.customfield = customfield
		return customCell
	else:
		return cell

static func GetEmote(cellHash : int) -> BaseCell:
	var hasInDB : bool = cellHash in EmotesDB
	assert(hasInDB, "Could not find the identifier %s in EmotesDB" % [cellHash])
	return EmotesDB[cellHash] if hasInDB else null

static func GetSkill(cellHash : int) -> SkillCell:
	var hasInDB : bool = cellHash in SkillsDB
	assert(hasInDB, "Could not find the identifier %s in SkillsDB" % [cellHash])
	return SkillsDB[cellHash] if hasInDB else null

static func GetRace(cellHash : int) -> RaceData:
	var hasInDB : bool = cellHash in RacesDB
	assert(hasInDB, "Could not find the identifier %s in RaceDB" % [cellHash])
	return RacesDB[cellHash] if hasInDB else null

static func GetHairstyle(cellHash : int) -> TraitData:
	var hasInDB : bool = cellHash in HairstylesDB
	assert(hasInDB, "Could not find the identifier %d in HairstylesDB" % [cellHash])
	return HairstylesDB[cellHash] if hasInDB else null

static func GetPalette(type : Palette, cellHash : int) -> TraitData:
	var hasInDB : bool = cellHash in PalettesDB[type]
	assert(hasInDB, "Could not find the identifier %d in PalettesDB" % [cellHash])
	return PalettesDB[type][cellHash] if hasInDB else null

#
static func Init():
	ParseMapsDB()
	ParseMusicsDB()
	ParseRacesDB()
	ParseHairstylesDB()
	ParsePalettesDB()
	ParseEmotesDB()
	ParseItemsDB()
	ParseSkillsDB()
	ParseEntitiesDB()
