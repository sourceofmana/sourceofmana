extends Node

#
const WarpObject			= preload("res://addons/tiled_importer/WarpObject.gd")
var pool : Dictionary		= {}

#
func GetMapPath(mapName : String) -> String:
	var path : String = ""
	var mapInstance = Launcher.DB.MapsDB[mapName]

	Launcher.Util.Assert(mapInstance != null, "Could not find the map " + mapName + " within the db")
	if mapInstance:
		path = mapInstance._path

	return path

#
func LoadMap(mapName : String) -> Node:
	var mapInstance : Node2D		= GetMap(mapName)
	var mapPath : String			= GetMapPath(mapName)

	if mapInstance == null:
		mapInstance = Launcher.FileSystem.LoadMap(mapPath)

	if mapInstance != null:
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
			Launcher.Util.Assert(ret, "Could not remove map (" + map + ") from the pool")

#
func RefreshPool(currentMap : Node2D):
	var adjacentMaps : Array = []
	if currentMap.get_node("Object"):
		for object in currentMap.get_node("Object").get_children():
			if object is WarpObject:
				adjacentMaps.append(object.destinationMap)

	for mapName in adjacentMaps:
		if pool.has(mapName) == false:
			pool[mapName] = LoadMap(mapName)

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
