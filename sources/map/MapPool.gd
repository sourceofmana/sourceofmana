extends RefCounted
class_name MapPool

#
var pool : Dictionary[int, Node2D]		= {}
var lastUsed : Dictionary[int, int]		= {}
var useCounter : int					= 0

var wantedMaps : PackedInt64Array		= []
var queuedMaps : PackedInt64Array		= []
var loadingMapID : int					= DB.UnknownHash
var loadingPath : String				= ""

#
func GetMap(mapID : int) -> Node2D:
	return pool.get(mapID, null)

func LoadMapLayers(mapID : int) -> Node2D:
	var mapNode : Node2D = GetMap(mapID)
	if mapNode == null:
		if mapID == loadingMapID:
			var layers : PackedScene = TakeLoadingScene()
			mapNode = layers.instantiate() if layers else null
		else:
			mapNode = Instantiate.LoadMapLayers(mapID)
		if mapNode:
			pool[mapID] = mapNode
	if mapNode:
		Touch(mapID)
	return mapNode

func Touch(mapID : int):
	useCounter += 1
	lastUsed[mapID] = useCounter

func FreeMap(mapID : int):
	var mapNode : Node2D = GetMap(mapID)
	if mapNode:
		mapNode.queue_free()
	pool.erase(mapID)
	lastUsed.erase(mapID)

func Clear():
	wantedMaps.clear()
	queuedMaps.clear()
	if loadingMapID != DB.UnknownHash:
		TakeLoadingScene()
	for mapID in pool.keys():
		FreeMap(mapID)

# Background loading
func Refresh(currentMapID : int, adjacentMaps : PackedInt64Array):
	wantedMaps = PackedInt64Array([currentMapID])
	queuedMaps.clear()
	for mapID in adjacentMaps:
		if wantedMaps.size() >= LauncherCommons.MapPoolMaxSize:
			break
		if mapID not in wantedMaps:
			wantedMaps.append(mapID)
			if mapID not in pool and mapID != loadingMapID:
				queuedMaps.append(mapID)
	Trim()

func Poll():
	if loadingMapID == DB.UnknownHash:
		StartNextLoad()
	elif ResourceLoader.load_threaded_get_status(loadingPath) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var mapID : int = loadingMapID
		var layers : PackedScene = TakeLoadingScene()
		if layers and mapID in wantedMaps and mapID not in pool:
			pool[mapID] = layers.instantiate()
			Touch(mapID)
			Trim()

func StartNextLoad():
	while not queuedMaps.is_empty():
		var mapID : int = queuedMaps[0]
		queuedMaps.remove_at(0)
		if mapID not in pool:
			var mapData : MapData = DB.MapsDB.get(mapID, null)
			if mapData and not mapData.layersPath.is_empty() and ResourceLoader.load_threaded_request(mapData.layersPath) == OK:
				loadingMapID = mapID
				loadingPath = mapData.layersPath
				return

func TakeLoadingScene() -> PackedScene:
	var layers : PackedScene = ResourceLoader.load_threaded_get(loadingPath) as PackedScene
	loadingMapID = DB.UnknownHash
	loadingPath = ""
	return layers

func Trim():
	while pool.size() > LauncherCommons.MapPoolMaxSize:
		var oldestMapID : int = DB.UnknownHash
		for mapID in pool:
			if mapID not in wantedMaps and (oldestMapID == DB.UnknownHash or lastUsed.get(mapID, 0) < lastUsed.get(oldestMapID, 0)):
				oldestMapID = mapID

		if oldestMapID == DB.UnknownHash:
			break

		FreeMap(oldestMapID)
