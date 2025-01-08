extends ServiceBase

#
var mainCamera : Camera2D		= null
var sceneCamera : Camera2D		= null
var minPos : Vector2			= Vector2.ZERO
var maxPos : Vector2			= Vector2.ONE
var zoomLevel : float			= 1.0

#
func SetBoundaries():
	if Launcher.Map:
		var mapBoundaries : Rect2i	= Launcher.Map.GetMapBoundaries()
		minPos						= mapBoundaries.position
		maxPos						= mapBoundaries.end

		if mainCamera:
			mainCamera.limit_left		= int(mapBoundaries.position.x)
			mainCamera.limit_right		= int(mapBoundaries.end.x)
			mainCamera.limit_top		= int(mapBoundaries.position.y)
			mainCamera.limit_bottom		= int(mapBoundaries.end.y)

		if sceneCamera:
			sceneCamera.limit_left		= int(mapBoundaries.position.x)
			sceneCamera.limit_right		= int(mapBoundaries.end.x)
			sceneCamera.limit_top		= int(mapBoundaries.position.y)
			sceneCamera.limit_bottom	= int(mapBoundaries.end.y)

func EnableSceneCamera(pos : Vector2):
	sceneCamera.global_position = pos
	sceneCamera.set_enabled(true)
	sceneCamera.make_current()

func DisableSceneCamera():
	sceneCamera.set_enabled(false)

func ZoomIn():
	zoomLevel = clampf(zoomLevel + ActorCommons.CameraZoomIncrement, ActorCommons.CameraZoomMin, ActorCommons.CameraZoomMax)
	UpdateZoom()

func ZoomOut():
	zoomLevel = clampf(zoomLevel - ActorCommons.CameraZoomIncrement, ActorCommons.CameraZoomMin, ActorCommons.CameraZoomMax)
	UpdateZoom()

func ZoomReset():
	zoomLevel = 1.0
	UpdateZoom()

func UpdateZoom():
	var zoomVector : Vector2 = Vector2(zoomLevel, zoomLevel)
	mainCamera.set_zoom(zoomVector)
	sceneCamera.set_zoom(zoomVector)

#
func _post_launch():
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(SetBoundaries):
		Launcher.Map.PlayerWarped.connect(SetBoundaries)

	if Launcher.Scene:
		var cameraPreset : PackedScene = FileSystem.LoadEntityComponent("Camera", false)
		sceneCamera = cameraPreset.instantiate()
		sceneCamera.set_name("SceneCamera")
		if sceneCamera:
			Launcher.Scene.add_child.call_deferred(sceneCamera)

		mainCamera = cameraPreset.instantiate()
		mainCamera.set_name("MainCamera")
		if mainCamera:
			Launcher.Scene.add_child.call_deferred(mainCamera)

	isInitialized = true

func Destroy():
	if sceneCamera and Launcher.Scene:
		sceneCamera.queue_free()
		sceneCamera = null
