extends Node

#
var pool : Dictionary[String, Node2D]		= {}

#
func LoadMapClientData(mapName : String) -> Node2D:
	var mapInstance : Node2D		= GetMap(mapName)
	var mapPath : String			= DB.GetMapPath(mapName)

	if mapInstance == null:
		mapInstance = FileSystem.LoadMap(mapPath, Path.MapClientExt)
		mapInstance.set_name(mapName)
		pool[mapName] = mapInstance

	return mapInstance

#
func GetMap(mapName : String) -> Node2D:
	return pool.get(mapName, null)

func FreeMap(mapName : String):
	var mapNode : Node2D = GetMap(mapName)
	if mapNode:
		mapNode.queue_free()
		pool.erase(mapName)

#
func RefreshPool(currentMap : Node2D):
	var adjacentMaps : Array = []
	if currentMap.has_node("Object"):
		for object in currentMap.get_node("Object").get_children():
			if object is WarpObject:
				adjacentMaps.append(object.destinationMap)

	for mapName in adjacentMaps:
		if not pool.has(mapName):
			pool[mapName] = LoadMapClientData(mapName as String)

	var poolCurrentSize : int	= pool.size()
	if poolCurrentSize > LauncherCommons.MapPoolMaxSize:
		ClearUnused(currentMap, adjacentMaps, poolCurrentSize - LauncherCommons.MapPoolMaxSize)

func ClearUnused(currentMap : Node2D, adjacentMaps : Array, nbToRemove : int):
	var mapToFree : Array = []
	for map in pool:
		if not adjacentMaps.has(map) && map != currentMap.name:
			mapToFree.append(map)

	for map in mapToFree:
		FreeMap(map)
		nbToRemove -= 1
		if nbToRemove <= 0:
			break
