extends Node

var ItemsDB : Dictionary			= {}
var MapsDB : Dictionary				= {}
var MusicsDB : Dictionary			= {}
var EthnicitiesDB : Dictionary		= {}
var HairstylesDB : Dictionary		= {}
var EntitiesDB : Dictionary			= {}

#
func ParseItemsDB():
	var Item = load(Launcher.Path.DBInstSrc + "Item.gd")
	var result = Launcher.FileSystem.LoadDB("items.json")

	if not result.is_empty():
		for key in result:
			var item = Item.new()
			item._id = key.to_int()
			item._name = result[key].Name
			item._description =  result[key].Description
			item._path = result[key].Path
			ItemsDB[key] = item

func ParseMapsDB():
	var Map = load(Launcher.Path.DBInstSrc + "Map.gd")
	var result = Launcher.FileSystem.LoadDB("maps.json")

	if not result.is_empty():
		for key in result:
			var map = Map.new()
			map._name = key
			map._path = result[key].Path
			MapsDB[key] = map

func ParseMusicsDB():
	var Music = load(Launcher.Path.DBInstSrc + "Music.gd")
	var result = Launcher.FileSystem.LoadDB("musics.json")

	if not result.is_empty():
		for key in result:
			var music = Music.new()
			music._name = key
			music._path = result[key].Path
			MusicsDB[key] = music

func ParseEthnicitiesDB():
	var Trait = load(Launcher.Path.DBInstSrc + "Trait.gd")
	var result = Launcher.FileSystem.LoadDB("ethnicities.json")

	if not result.is_empty():
		for key in result:
			var ethnicity = Trait.new()
			ethnicity._name = key
			ethnicity._path[Launcher.Entities.Trait.Gender.MALE] = result[key].Male
			ethnicity._path[Launcher.Entities.Trait.Gender.FEMALE] = result[key].Female
			ethnicity._path[Launcher.Entities.Trait.Gender.NONBINARY] = result[key].Nonbinary
			EthnicitiesDB[key] = ethnicity

func ParseHairstylesDB():
	var Trait = load(Launcher.Path.DBInstSrc + "Trait.gd")
	var result = Launcher.FileSystem.LoadDB("hairstyles.json")

	if not result.is_empty():
		for key in result:
			var hairstyle = Trait.new()
			hairstyle._name = key
			hairstyle._path[Launcher.Entities.Trait.Gender.MALE] = result[key].Male
			hairstyle._path[Launcher.Entities.Trait.Gender.FEMALE] = result[key].Female
			hairstyle._path[Launcher.Entities.Trait.Gender.NONBINARY] = result[key].Nonbinary
			HairstylesDB[key] = hairstyle

func ParseEntitiesDB():
	var Entity = load(Launcher.Path.DBInstSrc + "Entity.gd")
	var result = Launcher.FileSystem.LoadDB("entities.json")

	if not result.is_empty():
		for key in result:
			var entity = Entity.new()
			entity._id = key.to_int()
			entity._name = result[key].Name
			if "Ethnicity" in result[key]:
				entity._ethnicity = result[key].Ethnicity
			if "Gender" in result[key]:
				entity._gender = result[key].Gender
			if "Hairstyle" in result[key]:
				entity._hairstyle = result[key].Hairstyle
			if "Animation" in result[key]:
				entity._animation = result[key].Animation
			if "AnimationTree" in result[key]:
				entity._animationTree = result[key].AnimationTree
			if "NavigationAgent" in result[key]:
				entity._navigationAgent = result[key].NavigationAgent
			if "Camera" in result[key]:
				entity._camera = result[key].Camera
			if "Collision" in result[key]:
				entity._collision = result[key].Collision
			EntitiesDB[key] = entity

#
func _post_ready():
	ParseItemsDB()
	ParseMapsDB()
	ParseMusicsDB()
	ParseEthnicitiesDB()
	ParseHairstylesDB()
	ParseEntitiesDB()
