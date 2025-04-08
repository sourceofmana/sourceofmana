extends WindowPanel

@onready var textureRect : TextureRect				= $ScrollContainer/TextureRect
@onready var scrollContainer : ScrollContainer		= $ScrollContainer
@onready var playerPoint : TextureRect				= $ScrollContainer/TextureRect/PlayerPoint

var textureSize : Vector2							= Vector2.ZERO

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
	textureSize = textureRect.texture.get_size()
	if textureSize != Vector2.ZERO:
		maxSize = textureSize
	if size.x > maxSize.x:
		size.x = maxSize.x
	if size.y > maxSize.y:
		size.y = maxSize.y

func Moved():
	if not Launcher.Map or not Launcher.Map.currentMapNode:
		return

	var mapSize : Vector2 = Launcher.Map.GetMapBoundaries()
	if mapSize.x != 0 and mapSize.y != 0:
		var posRatio : Vector2 = Launcher.Player.position / mapSize
		var minimapPlayerPos : Vector2 = posRatio * textureRect.size - Vector2(5, 5)
		var scrollPos : Vector2i = Vector2i(minimapPlayerPos - scrollContainer.size / 2)
		scrollPos.x = clampi(scrollPos.x, 0, int(textureSize.x - scrollContainer.size.x))
		scrollPos.y = clampi(scrollPos.y, 0, int(textureSize.y - scrollContainer.size.y))

		scrollContainer.set_h_scroll(scrollPos.x)
		scrollContainer.set_v_scroll(scrollPos.y)
		playerPoint.set_position(minimapPlayerPos)

#
func _on_texture_rect_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if textureSize.x != 0 and textureSize.y != 0:
				Launcher.Action.MoveTo(event.position / textureSize * Launcher.Map.GetMapBoundaries())

func _ready():
	var HBar : HScrollBar = scrollContainer.get_h_scroll_bar()
	HBar.set_scale(Vector2.ZERO)
	HBar.set_allow_greater(false)

	var VBar : VScrollBar = scrollContainer.get_v_scroll_bar()
	VBar.set_scale(Vector2.ZERO)
	VBar.set_allow_greater(false)
	_post_launch()

func _post_launch():
	if Launcher.Map:
		Launcher.Map.PlayerWarped.connect(Warped)
		Launcher.Map.PlayerMoved.connect(Moved)

func Destroy():
	if Launcher.Map:
		if Launcher.Map.PlayerWarped.is_connected(Warped):
			Launcher.Map.PlayerWarped.disconnect(Warped)
		if Launcher.Map.PlayerMoved.is_connected(Moved):
			Launcher.Map.PlayerMoved.disconnect(Moved)
