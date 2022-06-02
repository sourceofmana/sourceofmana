extends Node

var ItemsDB : Dictionary			= {}
var MapsDB : Dictionary				= {}
var MusicsDB : Dictionary			= {}
var EthnicityDB : Dictionary		= {}
var HairstyleDB : Dictionary		= {}

#
func ParseItemsDB():
	var Item = load(Launcher.Path.DBInstSrc + "Item.gd")
	var result = Launcher.FileSystem.LoadDB("items.json")

	if result != null:
		for key in result:
			var item = Item.new()
			item._id = key
			item._name = result[key].Name
			item._description =  result[key].Description
			item._path = result[key].Path
			ItemsDB[key] = item

func ParseMapsDB():
	var Map = load(Launcher.Path.DBInstSrc + "Map.gd")
	var result = Launcher.FileSystem.LoadDB("maps.json")

	if result != null:
		for key in result:
			var map = Map.new()
			map._name = key
			map._path = result[key].Path
			MapsDB[key] = map

func ParseMusicsDB():
	var Music = load(Launcher.Path.DBInstSrc + "Music.gd")
	var result = Launcher.FileSystem.LoadDB("musics.json")

	if result != null:
		for key in result:
			var music = Music.new()
			music._name = key
			music._path = result[key].Path
			MusicsDB[key] = music

func ParseEthnicitiesDB():
	var Trait = load(Launcher.Path.DBInstSrc + "Trait.gd")
	var result = Launcher.FileSystem.LoadDB("ethnicities.json")

	if result != null:
		for key in result:
			var ethnicity = Trait.new()
			ethnicity._name = key
			ethnicity._path[Launcher.Entities.Trait.Gender.MALE] = result[key].Male
			ethnicity._path[Launcher.Entities.Trait.Gender.FEMALE] = result[key].Female
			ethnicity._path[Launcher.Entities.Trait.Gender.NONBINARY] = result[key].Nonbinary
			MusicsDB[key] = ethnicity

func ParseHairstylesDB():
	var Trait = load(Launcher.Path.DBInstSrc + "Trait.gd")
	var result = Launcher.FileSystem.LoadDB("hairstyles.json")

	if result != null:
		for key in result:
			var hairstyle = Trait.new()
			hairstyle._name = key
			hairstyle._path[Launcher.Entities.Trait.Gender.MALE] = result[key].Male
			hairstyle._path[Launcher.Entities.Trait.Gender.FEMALE] = result[key].Female
			hairstyle._path[Launcher.Entities.Trait.Gender.NONBINARY] = result[key].Nonbinary
			MusicsDB[key] = hairstyle

#
func _post_ready():
	ParseItemsDB()
	ParseMapsDB()
	ParseMusicsDB()
	ParseEthnicitiesDB()
	ParseHairstylesDB()
