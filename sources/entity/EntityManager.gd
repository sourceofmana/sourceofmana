extends Node

var Trait : Node			= null

var activePlayer : Node2D	= null
var otherPlayers : Array	= []
var monsters : Array		= []
var npcs : Array			= []

#
func Create(entity : Object, isPlayable : bool) -> Node2D:
	var instanciatedEntity = null
	if entity:
		instanciatedEntity = Launcher.FileSystem.LoadScene("presets/Entity")
		if entity._ethnicity or entity._gender:
			instanciatedEntity.sprite = Launcher.FileSystem.LoadPreset("sprites/" + entity._ethnicity + entity._gender)
			instanciatedEntity.add_child(instanciatedEntity.sprite)
		if entity._animation:
			instanciatedEntity.animation = Launcher.FileSystem.LoadPreset("animations/" + entity._animation)
			var canFetchAnimTree = instanciatedEntity.animation != null && instanciatedEntity.animation.has_node("AnimationTree")
			Launcher.Util.Assert(canFetchAnimTree, "No AnimationTree found")
			if canFetchAnimTree:
				instanciatedEntity.animationTree = instanciatedEntity.animation.get_node("AnimationTree")
			instanciatedEntity.add_child(instanciatedEntity.animation)
		if entity._navigationAgent:
			instanciatedEntity.agent = Launcher.FileSystem.LoadPreset("navigations/" + entity._navigationAgent)
			instanciatedEntity.add_child(instanciatedEntity.agent)
		if entity._camera && isPlayable:
			instanciatedEntity.camera = Launcher.FileSystem.LoadPreset("cameras/" + entity._camera)
			instanciatedEntity.add_child(instanciatedEntity.camera)
		if entity._collision:
			instanciatedEntity.collision = Launcher.FileSystem.LoadPreset("collisions/" + entity._collision)
			instanciatedEntity.add_child(instanciatedEntity.collision)

	return instanciatedEntity

func Spawn(entityID : String, entityName : String = "", isPlayable : bool = false) -> Node2D:
	var instanciatedEntity = null
	for entityDB in Launcher.DB.EntitiesDB:
		var entityRef = Launcher.DB.EntitiesDB[entityDB]
		if entityDB == entityID || entityRef._name == entityID:
			instanciatedEntity = Create(entityRef, isPlayable)
			if entityName.length() == 0:
				entityName = entityID
			instanciatedEntity.entityName = entityName
			instanciatedEntity.name = entityName
			instanciatedEntity.isPlayableController = isPlayable

	Launcher.Util.Assert(instanciatedEntity != null, "Could not create the entity: " + entityID)
	return instanciatedEntity

#
func RandomLocationInNavigationLayer(map : Node2D) -> Vector2:
	if map && map.has_node("Navigation"):
		var nav : NavigationRegion2D = map.get_node("Navigation")
		if nav && nav.navpoly:
			var outlineCount : int = nav.navpoly.get_outline_count()
			if outlineCount > 0:
				var polygon : PackedVector2Array = nav.navpoly.get_outline(0)
				var triangulation : PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
				var triangulationSize : int = triangulation.size()
				if triangulationSize >= 3:
					# Cache the triangulation to prevent to re-generate it
					var randTriangleID : int = randi_range(0, triangulationSize - 3)
					var a : Vector2 = polygon[triangulation[randTriangleID + 0]]
					var b : Vector2 = polygon[triangulation[randTriangleID + 1]]
					var c : Vector2 = polygon[triangulation[randTriangleID + 2]]
					return a + sqrt(randf()) * (-a + b + randf() * (c - b))
	return Vector2.ZERO


func UpdateWalkPaths(entity : Node2D):
	if entity.isCapturingMouseInput == false || entity.lastPosition.is_equal_approx(entity.position):
		var newPos = RandomLocationInNavigationLayer(Launcher.Map.activeMap)
		if newPos == Vector2.ZERO:
			var mapBoundaries : Rect2i	= Launcher.Map.GetMapBoundaries()
			newPos.x = randi_range(mapBoundaries.position.x, mapBoundaries.end.x)
			newPos.y = randi_range(mapBoundaries.position.y, mapBoundaries.end.y)
		entity.WalkToward(newPos)
	entity.UpdateInput()

func _process(_dt : float):
	for entity in npcs:
		UpdateWalkPaths(entity)
	for entity in monsters:
		UpdateWalkPaths(entity)

#
func _init():
	Trait = Launcher.FileSystem.LoadSource("entity/Trait.gd")
