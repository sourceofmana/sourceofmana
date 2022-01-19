extends Node2D

var mapList = {}

func LoadMapsJSON():
	var mapFile = File.new()
	mapFile.open("res://db/maps.json", File.READ)

	var mapListJSON = JSON.parse(mapFile.get_as_text())
	mapListJSON.close()

	mapList = mapListJSON.result
	assert(mapList != null, "Map list not found")

#func OnMapChange(path):
	#should change scene or just change node? Better to change node and reload our current mainworld
	#var ret = get_tree().change_scene("res://" + path)
	#assert(ret == OK, "Could not find the scene")

func GetMapBoundaries(map):
	var boundaries = Rect2()

	assert(map, "Map instance is not found, could not generate map boundaries")
	if map:
		var collisionLayer	= map.get_node("Collision")

		assert(collisionLayer, "Could not find a collision layer on map: " + map.get_name())
		if collisionLayer:
			var mapLimits			= collisionLayer.get_used_rect()
			var mapCellsize			= collisionLayer.cell_size

			boundaries.position.x	= mapCellsize.x * mapLimits.position.x
			boundaries.end.x		= mapCellsize.x * mapLimits.end.x
			boundaries.position.y	= mapCellsize.y * mapLimits.position.y
			boundaries.end.y		= mapCellsize.y * mapLimits.end.y

	return boundaries

func _ready():
	LoadMapsJSON()
