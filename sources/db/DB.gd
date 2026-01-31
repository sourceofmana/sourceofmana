extends Object
class_name DB

static var MapsDB : Dictionary[int, FileData]				= {}
static var MusicDB : Dictionary[int, FileData]				= {}
static var RacesDB : Dictionary[int, RaceData]				= {}
static var HairstylesDB : Dictionary[int, FileData]			= {}
static var PalettesDB : Array[Dictionary]					= []
static var EntitiesDB : Dictionary[int, EntityData]			= {}
static var EmotesDB : Dictionary[int, BaseCell]				= {}
static var ItemsDB : Dictionary[int, ItemCell]				= {}
static var SkillsDB : Dictionary[int, SkillCell]			= {}
static var QuestsDB : Dictionary[int, QuestData]			= {}

static var hashDB : Dictionary				= {}
const UnknownHash : int						= -1
static var PlayerHash : int					= "Player".hash()
static var ShipHash : int					= "Ship".hash()
static var OceanHash : int					= "Ocean".hash()

enum Palette
{
	HAIR = 0,
	SKIN,
	EQUIPMENT,
	COUNT
}

#
static func ParseMapsDB():
	for resourcePath in FileSystem.ParseExtension(Path.MapDataPst, Path.RscExt):
		var map : MapServerData = FileSystem.LoadResource(resourcePath, false)
		var genericPath = resourcePath.get_slice(Path.MapDataPst, 1).get_slice(Path.RscExt, 0)
		var data : FileData = FileData.Create(map.name, genericPath)
		MapsDB[data._id] = data

static func ParseMusicDB():
	var result = FileSystem.LoadDB("music.json")

	if not result.is_empty():
		for key in result:
			var data : FileData = FileData.Create(key, result[key].Path)
			MusicDB[data._id] = data

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
			var data : FileData = FileData.Create(key, result[key])
			HairstylesDB[data._id] = data

static func ParsePalettesDB():
	PalettesDB.resize(Palette.COUNT)
	var result : Dictionary = FileSystem.LoadDB("palettes.json")

	if not result.is_empty():
		for categoryKey in result:
			var category : Dictionary = result[categoryKey]
			var categoryIdx : int = int(categoryKey)
			for key in category:
				var id = SetCellHash(key)
				assert(id not in PalettesDB[categoryIdx], "Duplicated cell in PalettesDB")
				PalettesDB[categoryIdx][id] = FileData.Create(key, category[key])

static func ParseEntitiesDB():
	var result = FileSystem.LoadDB("entities.json")

	if not result.is_empty():
		for key in result:
			var entity : EntityData = EntityData.Create(result[key])
			EntitiesDB[entity._id] = entity

static func ParseEmotesDB():
	for resourcePath in FileSystem.ParseResources(Path.EmotePst):
		var cell : BaseCell = FileSystem.LoadResource(resourcePath, false)
		cell.id = SetCellHash(cell.name)
		assert(not EmotesDB.has(cell.id), "Duplicated cell in EmotesDB")
		EmotesDB[cell.id] = cell

static func ParseItemsDB():
	for resourcePath in FileSystem.ParseResources(Path.ItemPst):
		var cell : ItemCell = FileSystem.LoadResource(resourcePath, false)
		cell.id = DB.SetCellHash(cell.name)
		assert(not ItemsDB.has(cell.id), "Duplicated cell in ItemsDB")
		ItemsDB[cell.id] = cell

static func ParseSkillsDB():
	for resourcePath in FileSystem.ParseResources(Path.SkillPst):
		var cell : SkillCell = FileSystem.LoadResource(resourcePath, false)
		cell.Instantiate()
		cell.id = SetCellHash(cell.name)
		assert(SkillsDB.has(cell.id) == false, "Duplicated cell in SkillsDB")
		SkillsDB[cell.id] = cell

static func ParseQuestsDB():
	for resourcePath in FileSystem.ParseResources(Path.QuestPst):
		var quest : QuestData = FileSystem.LoadResource(resourcePath, false)
		quest.id = quest.name.hash()
		assert(QuestsDB.has(quest.id) == false, "Duplicated quest in QuestsDB")
		QuestsDB[quest.id] = quest

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
	assert(hasHash, "Cell hash doesn't exist for " + cellname)
	return hashDB[cellname] if hasHash else UnknownHash

#
static func GetItem(cellHash : int, customfield : String = "") -> ItemCell:
	var cell : ItemCell = ItemsDB.get(cellHash, null)
	assert(cell != null, "Could not find the identifier %s in ItemsDB" % [cellHash])
	if cell and customfield != cell.customfield:
		var customCell = cell.duplicate()
		customCell.customfield = customfield

		if HasCellHash(customfield):
			var paletteHash : int = GetCellHash(customfield)
			if paletteHash in PalettesDB[Palette.EQUIPMENT]:
				var paletteData : FileData = DB.GetPalette(DB.Palette.EQUIPMENT, paletteHash)
				if paletteData:
					customCell.shader = FileSystem.LoadPalette(paletteData._path)
		return customCell
	else:
		return cell

static func GetEntity(entityHash : int) -> EntityData:
	var data : EntityData = EntitiesDB.get(entityHash, null)
	assert(data != null, "Could not find the identifier %s in EntitiesDB" % [entityHash])
	return data

static func GetEmote(cellHash : int) -> BaseCell:
	var data : BaseCell = EmotesDB.get(cellHash, null)
	assert(data != null, "Could not find the identifier %s in EmotesDB" % [cellHash])
	return data

static func GetSkill(cellHash : int) -> SkillCell:
	var data : SkillCell = SkillsDB.get(cellHash, null)
	assert(data != null, "Could not find the identifier %s in SkillsDB" % [cellHash])
	return data

static func GetRace(cellHash : int) -> RaceData:
	var data : RaceData = RacesDB.get(cellHash, null)
	assert(data != null, "Could not find the identifier %s in RacesDB" % [cellHash])
	return data

static func GetHairstyle(cellHash : int) -> FileData:
	var data : FileData = HairstylesDB.get(cellHash, null)
	assert(data != null, "Could not find the identifier %s in HairstylesDB" % [cellHash])
	return data

static func GetPalette(type : Palette, cellHash : int) -> FileData:
	var data : FileData = PalettesDB[type].get(cellHash, null)
	assert(data != null, "Could not find the identifier %s in PalettesDB" % [cellHash])
	return data

static func GetQuest(questID : int) -> QuestData:
	var data : QuestData = QuestsDB.get(questID, null)
	assert(data != null, "Could not find the identifier %s in QuestsDB" % [questID])
	return data

#
static func Init():
	ParseMapsDB()
	ParseMusicDB()
	ParsePalettesDB()
	ParseRacesDB()
	ParseHairstylesDB()
	ParseEmotesDB()
	ParseItemsDB()
	ParseSkillsDB()
	ParseEntitiesDB()
	ParseQuestsDB()
