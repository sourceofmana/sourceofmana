extends WindowPanel

@onready var textureRect : TextureRect				= $ScrollContainer/TextureRect
@onready var scrollContainer : ScrollContainer		= $ScrollContainer
@onready var playerPoint : TextureRect				= $ScrollContainer/TextureRect/PlayerPoint

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

func Moved():
	var mapSize : Vector2 = Launcher.Map.GetMapBoundaries()
	if mapSize.x != 0 and mapSize.y != 0:
		var posRatio : Vector2 = Launcher.Player.position / mapSize
		var minimapPlayerPos : Vector2 = posRatio * textureRect.size
		# PlayerPos centered on the minimap minus scrollbar size (even hidden, they are still taking some extra spaces
		var scrollPos : Vector2i = Vector2i(minimapPlayerPos - scrollContainer.size / 2 - Vector2(10, 10))
		scrollContainer.set_h_scroll(scrollPos.x)
		scrollContainer.set_v_scroll(scrollPos.y)
		playerPoint.set_position(minimapPlayerPos)

#
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
	textureRect.item_rect_changed.connect(Moved)

func Destroy():
	if Launcher.Map:
		if Launcher.Map.PlayerWarped.is_connected(Warped):
			Launcher.Map.PlayerWarped.disconnect(Warped)
		if Launcher.Map.PlayerMoved.is_connected(Moved):
			Launcher.Map.PlayerMoved.disconnect(Moved)
	if textureRect.item_rect_changed.is_connected(Moved):
		textureRect.item_rect_changed.disconnect(Moved)
