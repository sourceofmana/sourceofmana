extends ScrollContainer

@onready var textureRect : TextureRect = $TextureRect

#
func Warped():
	if textureRect:
		var mapName : String = Launcher.Map.mapNode.get_name()
		Launcher.Util.Assert(mapName.is_empty() == false, "Could not fetch the active map name")
		if mapName.is_empty() == false:
			var mapPath : String = Launcher.DB.GetMapPath(mapName)
			Launcher.Util.Assert(mapPath.is_empty() == false, "Could not fetch the active map path")
			if mapPath.is_empty() == false:
				var resource : Resource = Launcher.FileSystem.LoadMinimap(mapPath)
				Launcher.Util.Assert(resource != null, "Could not load the minimap resource")
				if resource:
					textureRect.set_texture(resource)

#
func _ready():
	get_h_scroll_bar().scale = Vector2.ZERO
	get_v_scroll_bar().scale = Vector2.ZERO

	if Launcher.Map:
		Launcher.Map.PlayerWarped.connect(self.Warped)

func _process(_delta):
	if Launcher.Camera.mainCamera:
		var screenCenter : Vector2	= Launcher.Camera.mainCamera.get_target_position()
		var mapSize : Vector2		= Vector2(Launcher.Camera.mainCamera.limit_right, Launcher.Camera.mainCamera.limit_bottom)
		if mapSize.x != 0 && mapSize.y != 0:
			var posRatio : Vector2 = screenCenter / mapSize
			var minimapWindowSize = get_node("TextureRect").size
			var scrollPos : Vector2i = Vector2i(minimapWindowSize * posRatio - size / 2)
			get_parent().maxSize = minimapWindowSize
			set_h_scroll(scrollPos.x)
			set_v_scroll(scrollPos.y)
