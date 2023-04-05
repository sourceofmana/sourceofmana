extends Node

var Instantiate : Object			= load("res://sources/db/Instantiate.gd").new()

var MapsDB : Dictionary				= {}
var MusicsDB : Dictionary			= {}
var EthnicitiesDB : Dictionary		= {}
var HairstylesDB : Dictionary		= {}
var EntitiesDB : Dictionary			= {}
var EmotesDB : Dictionary			= {}


func ParseMapsDB():
	var Map		= Launcher.FileSystem.LoadDBInstance("Map.gd")
	var result	= Launcher.FileSystem.LoadDB("maps.json")

	if not result.is_empty():
		for key in result:
			var map = Map.new()
			map._name = key
			map._path = result[key].Path
			MapsDB[key] = map

func ParseMusicsDB():
	var Music	= Launcher.FileSystem.LoadDBInstance("Music.gd")
	var result	= Launcher.FileSystem.LoadDB("musics.json")

	if not result.is_empty():
		for key in result:
			var music = Music.new()
			music._name = key
			music._path = result[key].Path
			MusicsDB[key] = music

func ParseEthnicitiesDB():
	var Trait	= Launcher.FileSystem.LoadDBInstance("Trait.gd")
	var result	= Launcher.FileSystem.LoadDB("ethnicities.json")

	if not result.is_empty():
		for key in result:
			var ethnicity = Trait.new()
			ethnicity._name = key
			ethnicity._path.append(result[key].Male)
			ethnicity._path.append(result[key].Female)
			ethnicity._path.append(result[key].Nonbinary)
			EthnicitiesDB[key] = ethnicity

func ParseHairstylesDB():
	var Trait	= Launcher.FileSystem.LoadDBInstance("Trait.gd")
	var result	= Launcher.FileSystem.LoadDB("hairstyles.json")

	if not result.is_empty():
		for key in result:
			var hairstyle = Trait.new()
			hairstyle._name = key
			hairstyle._path.append(result[key].Male)
			hairstyle._path.append(result[key].Female)
			hairstyle._path.append(result[key].Nonbinary)
			HairstylesDB[key] = hairstyle

func ParseEntitiesDB():
	var Entity	= Launcher.FileSystem.LoadDBInstance("Entity.gd")
	var result	= Launcher.FileSystem.LoadDB("entities.json")

	if not result.is_empty():
		for key in result:
			var entity = Entity.new()
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
			if "WalkSpeed" in result[key]:
				entity._walkSpeed = result[key].WalkSpeed
			if "DisplayName" in result[key]:
				entity._displayName = result[key].DisplayName
			EntitiesDB[key] = entity

#
func ParseEmotesDB():
	var Emote	= Launcher.FileSystem.LoadDBInstance("Emote.gd")
	var result	= Launcher.FileSystem.LoadDB("emotes.json")

	if not result.is_empty():
		for key in result:
			var emote = Emote.new()
			emote._id = key.to_int()
			emote._name = result[key].Name
			emote._path = result[key].Path
			EmotesDB[key] = emote

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
	ParseEntitiesDB()
	ParseEmotesDB()
