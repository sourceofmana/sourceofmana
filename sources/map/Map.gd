extends Node2D

#
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

func UpdateBackgroundMusic(map):
	Launcher.Audio.Load(map.get_meta("music") )
#	Launcher.Audio.Play()
