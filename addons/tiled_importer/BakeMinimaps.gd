@tool
extends EditorScript

#
const MinimapScale : float			= 1.0 / 16.0
# Rendered larger with mipmaps for averaged colours, then nearest downscaled for crisp pixels
const RenderFactor : int			= 2
const BakeAllAction : StringName	= &"bake_all"

static var running : EditorScript	= null
var isBaking : bool					= false

#
func _run():
	if running:
		return
	running = self

	var dialog : EditorFileDialog = EditorFileDialog.new()
	dialog.title = "Select a map to bake"
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.current_dir = Path.MapRsc
	dialog.ok_button_text = "Bake Selected"
	dialog.add_filter("*.tmx", "Tiled maps")
	dialog.add_button("Bake All", true, BakeAllAction)

	dialog.files_selected.connect(OnMapsSelected.bind(dialog))
	dialog.custom_action.connect(OnCustomAction.bind(dialog))
	dialog.canceled.connect(OnCanceled.bind(dialog))

	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio(0.5)

func OnMapsSelected(tmxPaths : PackedStringArray, dialog : EditorFileDialog):
	dialog.queue_free()

	var mapDataPaths : PackedStringArray = []
	for tmxPath in tmxPaths:
		var mapDataPath : String = GetMapDataPath(tmxPath)
		if mapDataPath.is_empty():
			Util.PrintLog("Minimap", "Could not find the imported map data of " + tmxPath)
		else:
			mapDataPaths.append(mapDataPath)

	BakeMaps(mapDataPaths)

func OnCustomAction(action : StringName, dialog : EditorFileDialog):
	if action == BakeAllAction:
		dialog.hide()
		dialog.queue_free()
		BakeMaps(FileSystem.ParseResources(Path.MapDataPst))

func OnCanceled(dialog : EditorFileDialog):
	dialog.queue_free()
	if not isBaking:
		running = null

func GetMapDataPath(tmxPath : String) -> String:
	var mapNameMatch : RegExMatch = RegEx.create_from_string("<property name=\"name\" value=\"([^\"]*)\"").search(FileAccess.get_file_as_string(tmxPath))
	if not mapNameMatch:
		return ""

	var mapDataPath : String = Path.MapDataPst + tmxPath.get_slice(Path.MapRsc, 1).get_base_dir() + "/" + mapNameMatch.get_string(1) + Path.RscExt
	return mapDataPath if FileSystem.ResourceExists(mapDataPath) else ""

func BakeMaps(mapDataPaths : PackedStringArray):
	isBaking = true
	var host : Node = EditorInterface.get_base_control()
	var bakedCount : int = 0
	Util.PrintLog("Minimap", "Baking minimaps...")

	for mapDataPath in mapDataPaths:
		var mapData : MapData = ResourceLoader.load(mapDataPath, "", ResourceLoader.CACHE_MODE_IGNORE)
		if mapData and not mapData.layersPath.is_empty():
			if await Bake(host, mapData, mapDataPath):
				bakedCount += 1

	EditorInterface.get_resource_filesystem().scan()
	Util.PrintLog("Minimap", "Baked %d minimaps" % bakedCount)
	isBaking = false
	running = null

func Bake(host : Node, mapData : MapData, mapDataPath : String) -> bool:
	var layers : PackedScene = ResourceLoader.load(mapData.layersPath, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if not layers:
		return false

	var mapNode : Node2D = layers.instantiate()
	var mapSize : Vector2 = mapNode.get_meta("MapBoundaries", Vector2.ZERO)
	if mapSize.x <= 0 or mapSize.y <= 0:
		mapNode.free()
		return false

	StripToVisuals(mapNode)
	UseMipmappedTilesets(mapNode)

	var minimapPath : String = Path.MinimapRsc + mapData.layersPath.trim_prefix(Path.MapLayerPst).trim_suffix(Path.SceneExt) + Path.GfxExt
	var minimapSize : Vector2i = Vector2i((mapSize * MinimapScale).round()).max(Vector2i.ONE)
	var renderScale : float = MinimapScale * RenderFactor
	var viewport : SubViewport = SubViewport.new()
	viewport.size = minimapSize * RenderFactor
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.add_child(mapNode)
	host.add_child(viewport)
	viewport.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(renderScale, renderScale))

	# Make sure the map is loaded and drawn
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	RenderingServer.force_draw(false)

	var image : Image = viewport.get_texture().get_image()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.queue_free()
	if not image or image.is_empty():
		Util.PrintLog("Minimap", "Could not render " + mapData.layersPath)
		return false

	image.resize(minimapSize.x, minimapSize.y, Image.INTERPOLATE_NEAREST)
	FileSystem.CreateRecursiveDirectory(minimapPath.get_base_dir())
	if image.save_png(minimapPath) != OK:
		Util.PrintLog("Minimap", "Could not save " + minimapPath)
		return false

	if mapData.minimapPath != minimapPath:
		mapData.minimapPath = minimapPath
		ResourceSaver.save(mapData, mapDataPath)
	return true

func UseMipmappedTilesets(mapNode : Node):
	var tileSets : Dictionary[TileSet, bool] = {}
	for layer in mapNode.find_children("*", "TileMapLayer", true, false):
		var tileSet : TileSet = layer.tile_set
		if not tileSet or tileSet in tileSets:
			continue

		tileSets[tileSet] = true

		for sourceIdx in tileSet.get_source_count():
			var atlas : TileSetAtlasSource = tileSet.get_source(tileSet.get_source_id(sourceIdx))
			if atlas and atlas.texture:
				atlas.texture = CreateMipmappedTexture(atlas.texture)

func CreateMipmappedTexture(texture : Texture2D) -> Texture2D:
	var image : Image = texture.get_image()
	if not image:
		return texture

	if image.is_compressed():
		image.decompress()
	image.generate_mipmaps()

	return ImageTexture.create_from_image(image)

func StripToVisuals(node : Node) -> bool:
	if node is CanvasLayer or node.name == "Effects":
		return false

	var keep : bool = node is TileMapLayer or node is Sprite2D
	for child in node.get_children():
		if StripToVisuals(child):
			keep = true
		else:
			node.remove_child(child)
			child.free()

	return keep
