extends Node

const Item						= preload("res://sources/db/instance/Item.gd")
var ItemsDBPath : String		= "res://data/db/items.json"
var ItemsDB : Array				= []

const Map						= preload("res://sources/db/instance/Map.gd")
var MapsDBPath : String			= "res://data/db/maps.json"
var MapsDB : Array				= []


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
			var item : Item = Item.new()
			item._id = key
			item._name = result[key].Name
			item._description =  result[key].Description
			item._path = result[key].Path
			ItemsDB.append(item)

func ParseMapsDB():
	var result = Parse(MapsDBPath)
	if result != null:
		for key in result:
			var map : Map = Map.new()
			map._name = key
			map._path = result[key].Path
			MapsDB.append(map)

#
func Init():
	ParseItemsDB()
	ParseMapsDB()
	print(ItemsDB)
	print(MapsDB)
