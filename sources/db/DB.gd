extends Node

var Item							= load(Launcher.Path.DBInstSrc + "Item.gd")
var ItemsDBPath : String			= Launcher.Path.DBRsc + "items.json"
var ItemsDB : Dictionary			= {}

var Map								= preload("res://sources/db/instance/Map.gd")
var MapsDBPath : String				= Launcher.Path.DBRsc + "maps.json"
var MapsDB : Dictionary				= {}

var Music							= preload("res://sources/db/instance/Music.gd")
var MusicsDBPath : String			= Launcher.Path.DBRsc + "musics.json"
var MusicsDB : Dictionary			= {}

#
func Parse(path : String):
	var result
	var DBFile : File = File.new()
	var err : int = DBFile.open(path, File.READ)

	if err == OK:
		var DBJson : JSONParseResult = JSON.parse(DBFile.get_as_text())
		DBFile.close()

		if DBJson.error == OK:
			result = DBJson.result
		else:
			print("DB.Parse: Error loading JSON file '" + str(path) + "'.")
			print("\tError: ", DBJson.error)
			print("\tError Line: ", DBJson.error_line)
			print("\tError String: ", DBJson.error_string)
	else:
		print("DB.Parse: Error loading JSON file '" + str(path) + "'.")
		print("\tError: ", err)

	return result

#
func ParseItemsDB():
	var result = Parse(ItemsDBPath)
	if result != null:
		for key in result:
			var item = Item.new()
			item._id = key
			item._name = result[key].Name
			item._description =  result[key].Description
			item._path = result[key].Path
			ItemsDB[key] = item

func ParseMapsDB():
	var result = Parse(MapsDBPath)
	if result != null:
		for key in result:
			var map = Map.new()
			map._name = key
			map._path = result[key].Path
			MapsDB[key] = map

func ParseMusicsDB():
	var result = Parse(MusicsDBPath)
	if result != null:
		for key in result:
			var music = Music.new()
			music._name = key
			music._path = result[key].Path
			MusicsDB[key] = music

#
func _init():
	ParseItemsDB()
	ParseMapsDB()
	ParseMusicsDB()
