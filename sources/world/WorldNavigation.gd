extends Node
class_name WorldNavigation

# Instance init
static func LoadData(map : WorldMap):
	var obj : Object = Instantiate.LoadMapNavigation(map.id)
	if obj:
		map.navPoly = obj

static func CreateInstance(inst : WorldInstance):
	if inst.map.navPoly:
		if not inst.map.mapRID.is_valid():
			inst.map.mapRID = inst.get_world_2d().get_navigation_map()
			if not inst.map.mapRID.is_valid():
				inst.map.mapRID = NavigationServer2D.map_create()
			NavigationServer2D.map_set_active(inst.map.mapRID, true)
			NavigationServer2D.map_set_cell_size(inst.map.mapRID, inst.map.navPoly.cell_size)

			inst.map.regionRID = NavigationServer2D.region_create()
			NavigationServer2D.region_set_map(inst.map.regionRID, inst.map.mapRID)
			NavigationServer2D.region_set_navigation_polygon(inst.map.regionRID, inst.map.navPoly)
			NavigationServer2D.region_set_navigation_layers(inst.map.regionRID, 1)

# Getter
static func GetPathLengthSquared(agent : BaseAgent, pos : Vector2) -> float:
	if agent:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
		if inst:
			var path : PackedVector2Array = NavigationServer2D.map_get_path(inst.map.mapRID, agent.position, pos, true)
			return Util.UnrollPathLength(path)
	return INF

static func GetDistanceSquared(agent : BaseAgent, pos : Vector2) -> float:
	return Vector2.ZERO.distance_squared_to((agent.position - pos) * SkillCommons.PerspectiveIncrease)

static func GetDistanceSquaredSafe(agent : BaseAgent, pos : Vector2) -> float:
	var pathLengthSquared : float = GetPathLengthSquared(agent, pos)
	if pathLengthSquared != INF:
		var distLengthSquared : float = GetDistanceSquared(agent, pos)
		if (distLengthSquared - pathLengthSquared) > ActorCommons.MismatchPathSquaredThreshold:
			pathLengthSquared = INF
	return pathLengthSquared

# Utils
static func GetRandomPosition(inst : WorldInstance) -> Vector2i:
	assert(inst != null && inst.map.navPoly != null && inst.map.navPoly.get_polygon_count() > 0, "No triangulation available")
	if inst != null && inst.map.navPoly != null && inst.map.navPoly.get_polygon_count() > 0:
		return NavigationServer2D.region_get_random_point(inst.map.regionRID, 1, false)
	assert(false, "Mob could not be spawned, no available point on the navigation mesh were found")
	return Vector2i.ZERO

static func GetRandomPositionAABB(inst : WorldInstance, pos : Vector2i, offset : Vector2i) -> Vector2i:
	assert(inst != null, "Could not create a random position for a non-initialized instance")
	if inst != null:
		for i in NetworkCommons.NavigationSpawnTry:
			var randPoint : Vector2i = Vector2i(randi_range(-offset.x, offset.x), randi_range(-offset.y, offset.y))
			randPoint += pos

			if NavigationServer2D.region_owns_point(inst.map.regionRID, randPoint):
				return NavigationServer2D.region_get_closest_point(inst.map.regionRID, randPoint)

		return GetRandomPosition(inst)
	return Vector2i.ZERO

static func GetSpawnPosition(inst : WorldInstance, spawn : SpawnObject) -> Vector2i:
	var position : Vector2i = Vector2i.ZERO
	if spawn.is_global:
		position = WorldNavigation.GetRandomPosition(inst)
	else:
		if spawn.spawn_offset == Vector2i.ZERO:
			position = spawn.spawn_position
		else:
			position = WorldNavigation.GetRandomPositionAABB(inst, spawn.spawn_position, spawn.spawn_offset)
		if position == Vector2i.ZERO:
			position = WorldNavigation.GetRandomPosition(inst)

	assert(position != Vector2i.ZERO, "Could not spawn the agent %s, no walkable position found" % spawn.id)
	return position
