extends Node

const Item						= preload("res://sources/db/instance/Item.gd")
var ItemsDBPath : String		= "res://data/db/items.json"
var ItemsDB : Array				= []

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
func ParseItemDB():
	var result = Parse(ItemsDBPath)
	if result != null:
		for key in result:
			var item : Item = Item.new()
			item._name = result[key].Name
			item._description =  result[key].Description
			item._path =  result[key].Path

			ItemsDB.append(item)

#
func Init():
	ParseItemDB()
