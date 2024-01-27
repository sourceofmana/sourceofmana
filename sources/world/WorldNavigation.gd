extends Node
class_name WorldNavigation

# Instance init
static func LoadData(map : WorldMap):
	var obj : Object = Instantiate.LoadMapData(map.name, Path.MapNavigationExt)
	if obj:
		map.navPoly = obj
		map.navPoly.cell_size = 0.1

static func CreateInstance(map : WorldMap, mapRID : RID):
	if map.navPoly:
		map.mapRID = mapRID if mapRID.is_valid() else NavigationServer2D.map_create()
		NavigationServer2D.map_set_active(map.mapRID, true)
		NavigationServer2D.map_set_cell_size(map.mapRID, map.navPoly.cell_size)

		map.regionRID = NavigationServer2D.region_create()
		NavigationServer2D.region_set_map(map.regionRID, map.mapRID)
		NavigationServer2D.region_set_navigation_polygon(map.regionRID, map.navPoly)

		NavigationServer2D.map_force_update(map.mapRID)

# Getter
static func GetPathLength(agent : BaseAgent, pos : Vector2) -> float :
	var path : PackedVector2Array = NavigationServer2D.map_get_path(agent.agent.get_navigation_map(), agent.position, pos, true)
	var pathLength : float = 0.0
	for i in range(0, path.size() - 1):
		pathLength += Vector2(path[i] - path[i+1]).length()
	return pathLength

# Utils
static func GetRandomPosition(map : WorldMap) -> Vector2i:
	Util.Assert(map != null && map.navPoly != null && map.navPoly.get_polygon_count() > 0, "No triangulation available")
	if map != null && map.navPoly != null && map.navPoly.get_polygon_count() > 0:
		var outlinesList : PackedVector2Array  = map.navPoly.get_vertices()

		var randPolygonID : int = randi_range(0, map.navPoly.get_polygon_count() - 1)
		var randPolygon : PackedInt32Array = map.navPoly.get_polygon(randPolygonID)

		var randVerticeID : int = randi_range(0, randPolygon.size() - 1)
		var a : Vector2 = outlinesList[randPolygon[randVerticeID]]
		var b : Vector2 = outlinesList[randPolygon[(randVerticeID + 1) % randPolygon.size()]]
		var c : Vector2 = outlinesList[randPolygon[(randVerticeID + 2) % randPolygon.size()]]

		return Vector2i(a + sqrt(randf()) * (-a + b + randf() * (c - b)))

	Util.Assert(false, "Mob could not be spawned, no available point on the navigation mesh were found")
	return Vector2i.ZERO

static func GetRandomPositionAABB(map : WorldMap, pos : Vector2i, offset : Vector2i) -> Vector2i:
	Util.Assert(map != null, "Could not create a random position for a non-initialized map")
	if map != null:
		for i in Launcher.Conf.GetInt("Navigation", "navigationSpawnTry", Launcher.Conf.Type.NETWORK):
			var randPoint : Vector2i = Vector2i(randi_range(-offset.x, offset.x), randi_range(-offset.y, offset.y))
			randPoint += pos

			var closestPoint : Vector2i = NavigationServer2D.map_get_closest_point(map.mapRID, randPoint)
			if randPoint == closestPoint:
				return randPoint

		return GetRandomPosition(map)
	return Vector2i.ZERO

static func GetSpawnPosition(map : WorldMap, spawn : SpawnObject) -> Vector2i:
	var position : Vector2i = Vector2i.ZERO
	if not spawn.is_global:
		position = WorldNavigation.GetRandomPositionAABB(map, spawn.spawn_position, spawn.spawn_offset)
	if position == Vector2i.ZERO:
		position = WorldNavigation.GetRandomPosition(map)

	Util.Assert(position != Vector2i.ZERO, "Could not spawn the agent %s, no walkable position found" % spawn.name)
	return position
