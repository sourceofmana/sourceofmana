extends WindowPanel

@onready var textureRect : TextureRect = $ScrollContainer/TextureRect
@onready var scrollContainer : ScrollContainer = $ScrollContainer
#
func Warped():
	if textureRect and Launcher.Map and Launcher.Map.mapNode:
		var mapName : String = Launcher.Map.mapNode.get_name()
		Util.Assert(mapName.is_empty() == false, "Could not fetch the active map name")
		if mapName.is_empty() == false:
			var mapPath : String = Launcher.DB.GetMapPath(mapName)
			Util.Assert(mapPath.is_empty() == false, "Could not fetch the active map path")
			if mapPath.is_empty() == false:
				var resource : Texture2D = FileSystem.LoadMinimap(mapPath)
				Util.Assert(resource != null, "Could not load the minimap resource")
				if resource:
					textureRect.set_texture(resource)

#
func _ready():
	scrollContainer.get_h_scroll_bar().scale = Vector2.ZERO
	scrollContainer.get_v_scroll_bar().scale = Vector2.ZERO

func _process(_delta : float):
	if Launcher.Camera != null && Launcher.Camera.mainCamera != null:
		var screenCenter : Vector2i	= Launcher.Camera.mainCamera.get_target_position()
		var mapSize : Vector2i		= Vector2i(Launcher.Camera.mainCamera.get_limit(SIDE_RIGHT), Launcher.Camera.mainCamera.get_limit(SIDE_BOTTOM))
		if mapSize.x != 0 && mapSize.y != 0:
			var posRatio : Vector2 = screenCenter / mapSize
			var minimapWindowSize : Vector2 = textureRect.size
			var scrollPos : Vector2i = Vector2i(minimapWindowSize * posRatio - size / 2)
			maxSize = minimapWindowSize
			scrollContainer.set_h_scroll(scrollPos.x)
			scrollContainer.set_v_scroll(scrollPos.y)

func _on_visibility_changed():
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(Warped):
		Launcher.Map.PlayerWarped.connect(Warped)
	Warped()
