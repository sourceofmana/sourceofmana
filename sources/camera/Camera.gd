extends Node

var mainCamera : Camera2D		= null

func SetBoundaries(entity : Node2D):
	if entity && entity.has_node("Camera"):
		mainCamera = entity.get_node("Camera")
		if mainCamera:
			var mapBoundaries : Rect2	= Launcher.Map.GetMapBoundaries()
			mainCamera.limit_left		= int(mapBoundaries.position.x)
			mainCamera.limit_right		= int(mapBoundaries.end.x)
			mainCamera.limit_top		= int(mapBoundaries.position.y)
			mainCamera.limit_bottom		= int(mapBoundaries.end.y)
