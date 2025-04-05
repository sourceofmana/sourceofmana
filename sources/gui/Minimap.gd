extends WindowPanel

@onready var textureRect : TextureRect = $ScrollContainer/TextureRect
@onready var scrollContainer : ScrollContainer = $ScrollContainer

#
func Warped():
	if not textureRect or not Launcher.Map:
		return
	if Launcher.Map.currentMapID == DB.UnknownHash:
		assert(false, "Could not fetch the active map name")
		return
	var mapData : FileData = DB.MapsDB.get(Launcher.Map.currentMapID, null)
	if not mapData:
		assert(false, "Could not retrieve the map ID from our map daabase")
		return
	var resource : Texture2D = FileSystem.LoadMinimap(mapData._path)
	if not resource:
		assert(false, "Could not load the minimap resource")
		return
	textureRect.set_texture(resource)

#
func _ready():
	scrollContainer.get_h_scroll_bar().scale = Vector2.ZERO
	scrollContainer.get_v_scroll_bar().scale = Vector2.ZERO
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(Warped):
		Launcher.Map.PlayerWarped.connect(Warped)

func _process(_delta : float):
	if visible and Launcher.Camera != null && Launcher.Camera.mainCamera != null:
		var screenCenter : Vector2	= Launcher.Camera.mainCamera.get_target_position()
		var mapSize : Vector2		= Vector2(Launcher.Camera.mainCamera.get_limit(SIDE_RIGHT), Launcher.Camera.mainCamera.get_limit(SIDE_BOTTOM))
		if not mapSize.is_zero_approx():
			var posRatio : Vector2 = screenCenter / mapSize
			var minimapWindowSize : Vector2 = textureRect.size
			var scrollPos : Vector2i = Vector2i(minimapWindowSize * posRatio - size / 2)
			maxSize = minimapWindowSize
			scrollContainer.set_h_scroll(scrollPos.x)
			scrollContainer.set_v_scroll(scrollPos.y)
