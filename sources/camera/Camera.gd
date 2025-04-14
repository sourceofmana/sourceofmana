extends ServiceBase

#
var mainCamera : Camera2D		= null
var sceneCamera : Camera2D		= null
var lastZoomLevel : int			= ActorCommons.CameraZoomDefault
var zoomLevel : int				= ActorCommons.CameraZoomDefault
var zoomSceneTween : Tween		= null 
var zoomMainTween : Tween		= null
var zoomTimer : Timer			= null

#
func SetBoundaries():
	if Launcher.Map:
		var cameraBoundary : Vector2i = Launcher.Map.GetMapBoundaries()

		if mainCamera:
			mainCamera.limit_left		= 0
			mainCamera.limit_right		= cameraBoundary.x
			mainCamera.limit_top		= 0
			mainCamera.limit_bottom		= cameraBoundary.y
			mainCamera.set_global_position(Vector2.ZERO)

		if sceneCamera:
			sceneCamera.limit_left		= 0
			sceneCamera.limit_right		= cameraBoundary.x
			sceneCamera.limit_top		= 0
			sceneCamera.limit_bottom	= cameraBoundary.y
			sceneCamera.set_global_position(Vector2.ZERO)

func EnableSceneCamera(pos : Vector2):
	if not sceneCamera:
		return

	var enableSmoothing : bool = sceneCamera.get_global_position() != Vector2.ZERO
	sceneCamera.set_position_smoothing_enabled(enableSmoothing)
	sceneCamera.set_global_position(pos)
	sceneCamera.set_enabled(true)
	sceneCamera.make_current()

func DisableSceneCamera():
	sceneCamera.set_enabled(false)

func IsZooming(level : int) -> bool:
	return zoomLevel == level

func ZoomAt(level : int):
	zoomLevel = clampi(level, 0, ActorCommons.CameraZoomLevels.size() - 1)
	UpdateZoom()

func ZoomIn():
	if not zoomTimer:
		zoomLevel = clampi(zoomLevel + 1, 0, ActorCommons.CameraZoomLevels.size() - 1)
		UpdateZoom()

func ZoomOut():
	if not zoomTimer:
		zoomLevel = clampi(zoomLevel - 1, 0, ActorCommons.CameraZoomLevels.size() - 1)
		UpdateZoom()

func ZoomReset():
	if not zoomTimer:
		zoomLevel = ActorCommons.CameraZoomDefault
		UpdateZoom()

func ZoomTweenCompleted(isMainCamera : bool):
	if isMainCamera:
		zoomMainTween = null
	else:
		zoomSceneTween = null

func ZoomTimerCompleted():
	zoomTimer = null

func UpdateZoom():
	if zoomLevel == lastZoomLevel:
		return

	lastZoomLevel = zoomLevel
	zoomTimer = Callback.SelfDestructTimer(mainCamera, ActorCommons.CameraZoomDelay / 2.0, ZoomTimerCompleted, [], "ZoomTimer")

	if zoomLevel < 0 or zoomLevel >= ActorCommons.CameraZoomLevels.size():
		assert(false, "Trying to set a wrong zoom level to our camera(s)")
		return

	var zoomVector : Vector2 = ActorCommons.CameraZoomLevels[zoomLevel]

	if zoomSceneTween:
		zoomSceneTween.kill()
	zoomSceneTween = sceneCamera.create_tween()
	zoomSceneTween.tween_property(sceneCamera, "zoom", zoomVector, ActorCommons.CameraZoomDelay).from(sceneCamera.zoom)
	zoomSceneTween.play()
	zoomSceneTween.tween_callback(ZoomTweenCompleted.bind(false))

	if zoomMainTween:
		zoomMainTween.kill()
	zoomMainTween = mainCamera.create_tween()
	zoomMainTween.tween_property(mainCamera, "zoom", zoomVector, ActorCommons.CameraZoomDelay).from(mainCamera.zoom)
	zoomMainTween.play()
	zoomMainTween.tween_callback(ZoomTweenCompleted.bind(true))

func SyncPlayerPosition():
	if Launcher.Player and mainCamera:
		var enableSmoothing : bool = mainCamera.get_global_position() != Vector2.ZERO
		mainCamera.set_position_smoothing_enabled(enableSmoothing)
		mainCamera.set_position(Launcher.Player.get_position())

func FocusPosition(position : Vector2):
	if mainCamera:
		mainCamera.set_position_smoothing_enabled(false)
		mainCamera.set_position(position)

#
func _post_launch():
	if Launcher.Map:
		if not Launcher.Map.MapLoaded.is_connected(SetBoundaries):
			Launcher.Map.MapLoaded.connect(SetBoundaries)
		if not Launcher.Map.PlayerWarped.is_connected(SyncPlayerPosition):
			Launcher.Map.PlayerWarped.connect(SyncPlayerPosition)

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
	if Launcher.Scene:
		if sceneCamera:
			sceneCamera.queue_free()
			sceneCamera = null

		if mainCamera:
			mainCamera.queue_free()
			mainCamera = null
