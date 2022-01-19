extends Node

enum Gender { MALE = 0, FEMALE, NONBINARY }

onready var Ethnicity		= LoadRessource("res://db/ethnicity.json", "Could not load all entity traits")
onready var Hairstyle		= LoadRessource("res://db/hairstyle.json", "Could not load all hairstyle traits")


func LoadRessource(path, err):
	var file = File.new()
	file.open(path, File.READ)

	var json = JSON.parse(file.get_as_text())
	file.close()

	assert(json.result != null, err)	
	return json.result
