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
	var mapData : MapData = DB.MapsDB.get(Launcher.Map.currentMapID, null)
	if not mapData:
		assert(false, "Could not retrieve the map ID from our map daabase")
		return
	if mapData.minimapPath.is_empty():
		assert(false, "Could not load the minimap resource")
		return
	LoadTexture(Launcher.Map.currentMapID, mapData.minimapPath)

func LoadTexture(mapID : int, path : String):
	if ResourceLoader.load_threaded_request(path) != OK:
		return
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	var resource : Texture2D = ResourceLoader.load_threaded_get(path) as Texture2D
	if resource and Launcher.Map and Launcher.Map.currentMapID == mapID:
		SetTexture(resource)

func SetTexture(resource : Texture2D):
	textureRect.set_texture(resource)
	textureSize = resource.get_size()
	if textureSize != Vector2.ZERO:
		maxSize = textureSize
	if size.x > maxSize.x:
		size.x = maxSize.x
	if size.y > maxSize.y:
		size.y = maxSize.y

func _on_visibility_changed():
	if is_visible_in_tree():
		Moved(true)

func Moved(forceSync : bool = false):
	if not Launcher.Map or not Launcher.Map.currentMapNode or not Launcher.Player:
		return

	var mapSize : Vector2 = Launcher.Map.GetMapBoundaries()
	if mapSize.x != 0 and mapSize.y != 0:
		var posRatio : Vector2 = Launcher.Player.position / mapSize
		var minimapPlayerPos : Vector2 = posRatio * textureRect.size - Vector2(5, 5)
		if not forceSync and minimapPlayerPos.is_equal_approx(playerPoint.get_position()):
			return
		playerPoint.set_position(minimapPlayerPos)
		# Deffer as scrollContainer ignores a scroll set while it is sorting its children
		CenterOnPlayer.call_deferred()

func CenterOnPlayer():
	var scrollPos : Vector2i = Vector2i(playerPoint.get_position() - scrollContainer.size / 2)
	scrollPos.x = clampi(scrollPos.x, 0, int(textureSize.x - scrollContainer.size.x))
	scrollPos.y = clampi(scrollPos.y, 0, int(textureSize.y - scrollContainer.size.y))
	scrollContainer.set_h_scroll(scrollPos.x)
	scrollContainer.set_v_scroll(scrollPos.y)

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
	HBar.changed.connect(Moved.bind(true))

	var VBar : VScrollBar = scrollContainer.get_v_scroll_bar()
	VBar.set_scale(Vector2.ZERO)
	VBar.set_allow_greater(false)
	VBar.changed.connect(Moved.bind(true))
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
