extends ServiceBase

#
var camera : Camera2D			= null
var remoteTransform : RemoteTransform2D = null
var cinematic : bool			= false
var lastZoomLevel : int			= ActorCommons.CameraZoomDefault
var zoomLevel : int				= ActorCommons.CameraZoomDefault
var zoomTween : Tween			= null
var zoomTimer : Timer			= null

#
func SetBoundaries():
	if Launcher.Map and camera:
		var cameraBoundary : Vector2i = Launcher.Map.GetMapBoundaries()
		camera.limit_left		= 0
		camera.limit_right		= cameraBoundary.x
		camera.limit_top		= 0
		camera.limit_bottom		= cameraBoundary.y

func LookAt(pos : Vector2, smooth : bool = true):
	if not camera:
		return

	var smoothCinematic : bool = smooth and camera.get_global_position() != Vector2.ZERO
	cinematic = smoothCinematic
	camera.set_position_smoothing_enabled(smoothCinematic)
	camera.set_global_position(pos)
	if smoothCinematic:
		if remoteTransform:
			remoteTransform.set_update_position(false)
	else:
		camera.reset_physics_interpolation()
		camera.force_update_scroll()

func ResetCinematic():
	if not camera or not cinematic:
		return

	cinematic = false
	camera.set_position_smoothing_enabled(false)
	if remoteTransform:
		remoteTransform.set_update_position(true)
	SyncPlayerPosition()

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

func ZoomTweenCompleted():
	zoomTween = null

func ZoomTimerCompleted():
	zoomTimer = null

func UpdateZoom():
	if zoomLevel == lastZoomLevel:
		return

	lastZoomLevel = zoomLevel
	zoomTimer = Callback.SelfDestructTimer(camera, ActorCommons.CameraZoomDelay / 2.0, ZoomTimerCompleted, [], "ZoomTimer")

	if zoomLevel < 0 or zoomLevel >= ActorCommons.CameraZoomLevels.size():
		assert(false, "Trying to set a wrong zoom level to our camera(s)")
		return

	var zoomVector : Vector2 = ActorCommons.CameraZoomLevels[zoomLevel]

	if zoomTween:
		zoomTween.kill()
	zoomTween = camera.create_tween()
	zoomTween.tween_property(camera, "zoom", zoomVector, ActorCommons.CameraZoomDelay).from(camera.zoom)
	zoomTween.play()
	zoomTween.tween_callback(ZoomTweenCompleted)

	SendViewportSize()

func GetViewportHalfSize() -> Vector2:
	if zoomLevel < 0 or zoomLevel >= ActorCommons.CameraZoomLevels.size():
		return Vector2(NetworkCommons.MaxVisibilityHalfWidth, NetworkCommons.MaxVisibilityHalfHeight)
	var viewportSize : Vector2 = Vector2(DisplayServer.window_get_size())
	var zoom : Vector2 = ActorCommons.CameraZoomLevels[zoomLevel]
	return Vector2.ZERO if zoom.is_zero_approx() else viewportSize / zoom / 2.0

func SendViewportSize():
	var halfSize : Vector2 = GetViewportHalfSize()
	Network.SetViewportSize(halfSize.x, halfSize.y)

func SyncPlayerPosition():
	if Launcher.Player and camera and not cinematic:
		camera.set_position_smoothing_enabled(false)
		camera.set_position(Launcher.Player.get_position())
		camera.force_update_scroll()

func OnPlayerMoved():
	ResetCinematic()

#
func _post_launch():
	if Launcher.Map:
		if not Launcher.Map.MapLoaded.is_connected(SetBoundaries):
			Launcher.Map.MapLoaded.connect(SetBoundaries)
		if not Launcher.Map.PlayerWarped.is_connected(SyncPlayerPosition):
			Launcher.Map.PlayerWarped.connect(SyncPlayerPosition)
		if not Launcher.Map.PlayerMoved.is_connected(OnPlayerMoved):
			Launcher.Map.PlayerMoved.connect(OnPlayerMoved)

	if Launcher.Scene:
		var cameraPreset : PackedScene = FileSystem.LoadEntityComponent("Camera", false)
		camera = cameraPreset.instantiate()
		camera.set_name("Camera")
		if camera:
			Launcher.Scene.add_child.call_deferred(camera)

	isInitialized = true

func Destroy():
	if Launcher.Scene:
		if camera:
			camera.queue_free()
			camera = null
