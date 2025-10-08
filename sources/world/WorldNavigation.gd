extends Node
class_name WorldNavigation

# Instance init
static func LoadData(map : WorldMap):
	var obj : Object = Instantiate.LoadMapData(map.id, Path.MapNavigationExt)
	if obj:
		map.navPoly = obj

static func CreateInstance(map : WorldMap, mapRID : RID):
	if map.navPoly:
		map.mapRID = mapRID if mapRID.is_valid() else NavigationServer2D.map_create()
		NavigationServer2D.map_set_active(map.mapRID, true)
		NavigationServer2D.map_set_cell_size(map.mapRID, map.navPoly.cell_size)

		map.regionRID = NavigationServer2D.region_create()
		NavigationServer2D.region_set_map(map.regionRID, map.mapRID)
		NavigationServer2D.region_set_navigation_polygon(map.regionRID, map.navPoly)
		NavigationServer2D.region_set_navigation_layers(map.regionRID, 1)

# Getter
static func GetPathLengthSquared(agent : BaseAgent, pos : Vector2) -> float:
	if agent:
		var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
		if map:
			var path : PackedVector2Array = NavigationServer2D.map_get_path(map.mapRID, agent.position, pos, true)
			return Util.UnrollPathLength(path)
	return INF

static func GetDistanceSquared(agent : BaseAgent, pos : Vector2) -> float:
	var pathLengthSquared : float = GetPathLengthSquared(agent, pos)
	if pathLengthSquared != INF:
		var distLengthSquared : float = agent.position.distance_squared_to(pos)
		return INF if (distLengthSquared - pathLengthSquared) > ActorCommons.MismatchPathSquaredThreshold else pathLengthSquared
	return pathLengthSquared

# Utils
static func GetRandomPosition(map : WorldMap) -> Vector2i:
	assert(map != null && map.navPoly != null && map.navPoly.get_polygon_count() > 0, "No triangulation available")
	if map != null && map.navPoly != null && map.navPoly.get_polygon_count() > 0:
		return NavigationServer2D.map_get_random_point(map.mapRID, 1, false)
	assert(false, "Mob could not be spawned, no available point on the navigation mesh were found")
	return Vector2i.ZERO

static func GetRandomPositionAABB(map : WorldMap, pos : Vector2i, offset : Vector2i) -> Vector2i:
	assert(map != null, "Could not create a random position for a non-initialized map")
	if map != null:
		for i in NetworkCommons.NavigationSpawnTry:
			var randPoint : Vector2i = Vector2i(randi_range(-offset.x, offset.x), randi_range(-offset.y, offset.y))
			randPoint += pos

			if NavigationServer2D.region_owns_point(map.regionRID, randPoint):
				return randPoint

		return GetRandomPosition(map)
	return Vector2i.ZERO

static func GetSpawnPosition(map : WorldMap, spawn : SpawnObject, hasNavigation : bool) -> Vector2i:
	var position : Vector2i = Vector2i.ZERO
	if not spawn.is_global:
		if hasNavigation:
			position = WorldNavigation.GetRandomPositionAABB(map, spawn.spawn_position, spawn.spawn_offset)
		else:
			position = spawn.spawn_position

	if position == Vector2i.ZERO:
		position = WorldNavigation.GetRandomPosition(map)

	assert(position != Vector2i.ZERO, "Could not spawn the agent %s, no walkable position found" % spawn.id)
	return position
