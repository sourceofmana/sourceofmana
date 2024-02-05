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
			var entity : EntityData = EntityData.new()
			entity._id = key.to_int()
			entity._name = result[key].Name
			if "Ethnicity" in result[key]:
				entity._ethnicity = result[key].Ethnicity
			if "Hairstyle" in result[key]:
				entity._hairstyle = result[key].Hairstyle
			if "NavigationAgent" in result[key]:
				entity._navigationAgent = result[key].NavigationAgent
			if "Collision" in result[key]:
				entity._collision = result[key].Collision
			if "Texture" in result[key]:
				entity._customTexture = result[key].Texture
			if "walkSpeed" in result[key]:
				entity._stats["walkSpeed"] = result[key].walkSpeed
			if "spirit" in result[key]:
				entity._stats["spirit"] = result[key].spirit
			if "DisplayName" in result[key]:
				entity._displayName = result[key].DisplayName
			if "SkillSet" in result[key]:
				for skillSetName in result[key].SkillSet:
					if SkillsDB.has(skillSetName):
						entity._skillSet.append(SkillsDB[skillSetName])
						entity._skillProba[SkillsDB[skillSetName]] = result[key].SkillSet[skillSetName]
			EntitiesDB[key] = entity

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
			var skill : SkillData = SkillData.new()
			skill._name = key
			skill._iconPath = result[key].IconPath
			if "CastPresetPath" in result[key]:
				skill._castPresetPath = result[key].CastPresetPath
			if "CastTextureOverride" in result[key]:
				skill._castTextureOverride = result[key].CastTextureOverride
			if "CastColor" in result[key]:
				skill._castColor = result[key].CastColor
			if "CastTime" in result[key]:
				skill._castTime = result[key].CastTime
			if "SkillPresetPath" in result[key]:
				skill._skillPresetPath = result[key].SkillPresetPath
			if "SkillColor" in result[key]:
				skill._skillColor = result[key].SkillColor
			if "SkillTime" in result[key]:
				skill._skillTime = result[key].SkillTime
			if "ProjectilePath" in result[key]:
				skill._projectilePath = result[key].ProjectilePath
			if "CooldownTime" in result[key]:
				skill._cooldownTime = result[key].CooldownTime
			if "State" in result[key]:
				skill._state = EntityCommons.State[result[key].State]
			if "Mode" in result[key]:
				skill._mode = Skill.TargetMode[result[key].Mode]
			if "Range" in result[key]:
				skill._range = result[key].Range
			if "Damage" in result[key]:
				skill._damage = result[key].Damage
			if "Heal" in result[key]:
				skill._heal = result[key].Heal
			if "Repeat" in result[key]:
				skill._repeat = result[key].Repeat
			if "StaminaCost" in result[key]:
				skill.stamina = result[key].StaminaCost
			if "ManaCost" in result[key]:
				skill.mana = result[key].ManaCost
			SkillsDB[key] = skill

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
