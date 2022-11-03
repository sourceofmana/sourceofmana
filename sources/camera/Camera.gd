extends Node

var mainCamera : Camera2D		= null

# makes sure the camera does not move outside of the map
func SetBoundaries(player : PlayerEntity):
	if player && player.camera:
		mainCamera = player.camera
		if mainCamera:
			var mapBoundaries : Rect2i	= Launcher.Map.GetMapBoundaries()
			mainCamera.limit_left		= int(mapBoundaries.position.x)
			mainCamera.limit_right		= int(mapBoundaries.end.x)
			mainCamera.limit_top		= int(mapBoundaries.position.y)
			mainCamera.limit_bottom		= int(mapBoundaries.end.y)
