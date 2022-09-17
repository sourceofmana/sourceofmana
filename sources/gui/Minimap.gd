extends ScrollContainer

#
func _ready():
	get_h_scroll_bar().scale = Vector2.ZERO
	get_v_scroll_bar().scale = Vector2.ZERO

func _process(_delta):
	if Launcher.Camera.mainCamera:
		var screenCenter : Vector2	= Launcher.Camera.mainCamera.get_target_position()
		var mapSize : Vector2		= Vector2(Launcher.Camera.mainCamera.limit_right, Launcher.Camera.mainCamera.limit_bottom)
		if mapSize.x != 0 && mapSize.y != 0:
			var posRatio : Vector2 = screenCenter / mapSize
			var minimapWindowSize = get_node("TextureRect").size
			var scrollPos : Vector2i = Vector2i(minimapWindowSize * posRatio - size / 2)

			set_h_scroll(scrollPos.x)
			set_v_scroll(scrollPos.y)
