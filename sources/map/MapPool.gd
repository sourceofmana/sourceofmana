extends Node

#
var pool : Dictionary[int, Node2D]		= {}

#
func LoadMapLayers(mapID : int) -> Node2D:
	var mapInstance : Node2D = GetMap(mapID)
	if mapInstance == null:
		mapInstance = Instantiate.LoadMapLayers(mapID)
		pool[mapID] = mapInstance
	return mapInstance

#
func GetMap(mapID : int) -> Node2D:
	return pool.get(mapID, null)

func FreeMap(mapID : int):
	var mapNode : Node2D = GetMap(mapID)
	if mapNode:
		mapNode.queue_free()
		pool.erase(mapID)

#
func RefreshPool():
	var adjacentMaps : Array[int] = []
	if Launcher.Map.currentMapNode.has_node("Object"):
		for object in Launcher.Map.currentMapNode.get_node("Object").get_children():
			if object is WarpObject:
				adjacentMaps.append(object.destinationID)

	for mapID in adjacentMaps:
		if mapID not in pool:
			pool[mapID] = Instantiate.LoadMapLayers(mapID)

	var poolCurrentSize : int = pool.size()
	if poolCurrentSize > LauncherCommons.MapPoolMaxSize:
		ClearUnused(adjacentMaps, poolCurrentSize - LauncherCommons.MapPoolMaxSize)

func ClearUnused(adjacentMaps : PackedInt64Array, nbToRemove : int):
	var mapToFree : Array[int] = []
	for mapID in pool:
		if mapID != Launcher.Map.currentMapID and mapID not in adjacentMaps:
			mapToFree.append(mapID)

	for mapID in mapToFree:
		FreeMap(mapID)
		nbToRemove -= 1
		if nbToRemove <= 0:
			break
