extends ServiceBase

var mainCamera : Camera2D		= null
var minPos : Vector2			= Vector2.ZERO
var maxPos : Vector2			= Vector2.ONE

# makes sure the camera does not move outside of the map
func SetBoundaries():
	if Launcher.Map and mainCamera:
		var mapBoundaries : Rect2i	= Launcher.Map.GetMapBoundaries()
		mainCamera.limit_left		= int(mapBoundaries.position.x)
		mainCamera.limit_right		= int(mapBoundaries.end.x)
		mainCamera.limit_top		= int(mapBoundaries.position.y)
		mainCamera.limit_bottom		= int(mapBoundaries.end.y)
		minPos						= mapBoundaries.position
		maxPos						= mapBoundaries.end

func _post_launch():
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(SetBoundaries):
		Launcher.Map.PlayerWarped.connect(SetBoundaries)

	isInitialized = true
