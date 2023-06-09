extends Node

#
var pool : Dictionary		= {}

#
func LoadMapClientData(mapName : String) -> Node2D:
	var mapInstance : Node2D		= GetMap(mapName)
	var mapPath : String			= Launcher.DB.GetMapPath(mapName)

	if mapInstance == null:
		mapInstance = Launcher.FileSystem.LoadMap(mapPath, Launcher.Path.MapClientExt)
		mapInstance.set_name(mapName)
		pool[mapName] = mapInstance

	return mapInstance

#
func GetMap(mapName : String) -> Node2D:
	var mapInstance : Node2D = null 
	if pool.has(mapName):
		mapInstance = pool.get(mapName)
	return mapInstance

func FreeMap(map : String):
	if map:
		if pool.get(map) != null:
			pool[map].queue_free()
			var ret : bool = pool.erase(map)
			Util.Assert(ret, "Could not remove map (" + map + ") from the pool")

#
func RefreshPool(currentMap : Node2D):
	var adjacentMaps : Array = []
	if currentMap.has_node("Object"):
		for object in currentMap.get_node("Object").get_children():
			if object is WarpObject:
				adjacentMaps.append(object.destinationMap)

	for mapName in adjacentMaps:
		if pool.has(mapName) == false:
			pool[mapName] = LoadMapClientData(mapName)

	var poolMaxSize : int		= Launcher.Conf.GetInt("MapPool", "maxSize", Launcher.Conf.Type.MAP)
	var poolCurrentSize : int	= pool.size()
	if poolCurrentSize > poolMaxSize:
		ClearUnused(currentMap, adjacentMaps, poolCurrentSize - poolMaxSize)

func ClearUnused(currentMap : Node2D, adjacentMaps : Array, nbToRemove : int):
	var mapToFree : Array = []
	for map in pool:
		if adjacentMaps.has(map) == false && map != currentMap.name:
			mapToFree.append(map)

	for map in mapToFree:
		FreeMap(map)
		nbToRemove -= 1
		if nbToRemove <= 0:
			break
