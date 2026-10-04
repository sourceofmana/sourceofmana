extends RefCounted
class_name ShaderWarmup

#
enum State
{
	IDLE = 0,
	RUNNING,
	DONE
}

static var state : State									= State.IDLE
static var warmedMaterials : Array[Material]				= []

const WarmerFrameLifetime : int								= 2

#
static func Start():
	if state != State.IDLE:
		return
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		Finish()
		return
	state = State.RUNNING

	var warmPaths : PackedStringArray = GetWarmPaths()
	var screenCenter : Vector2 = Launcher.GUI.get_viewport().get_visible_rect().get_center()
	var warmerRoot : Node2D = CreateWarmerRoot()

	var liveWarmers : Array[CanvasItem] = []
	for pathIdx in warmPaths.size():
		var resource : Resource = FileSystem.LoadResource(warmPaths[pathIdx], false)
		for warmer in CreateWarmers(resource, screenCenter):
			SpawnWarmer(warmerRoot, warmer)
			liveWarmers.push_back(warmer)

		Launcher.GUI.loadingControl.SetProgress(pathIdx + 1, warmPaths.size())
		await Launcher.get_tree().process_frame
		while liveWarmers.size() > WarmerFrameLifetime:
			liveWarmers.pop_front().queue_free()

	for _frame in WarmerFrameLifetime:
		await Launcher.get_tree().process_frame

	warmerRoot.queue_free()
	Finish()

static func Finish():
	state = State.DONE
	Launcher.shadersWarmed.emit()

# Setup
static func GetWarmPaths() -> PackedStringArray:
	var warmPaths : PackedStringArray = FileSystem.ParseExtension(Path.ShaderSrc, Path.ShaderExt)
	warmPaths.append_array(FileSystem.ParseExtension(Path.ParticlePst, Path.SceneExt))
	warmPaths.append_array(FileSystem.ParseExtension(Path.EntitySprite, Path.SceneExt))
	return warmPaths

static func CreateWarmerRoot() -> Node2D:
	var warmerRoot : Node2D = Node2D.new()
	Launcher.GUI.add_child(warmerRoot)
	Launcher.GUI.move_child(warmerRoot, 0)
	return warmerRoot

static func SpawnWarmer(warmerRoot : Node2D, warmer : CanvasItem):
	warmerRoot.add_child(warmer)
	if warmer is GPUParticles2D:
		warmer.restart()

static func RegisterMaterial(material : Material):
	if material and not warmedMaterials.has(material):
		warmedMaterials.push_back(material)

# Warmers
static func CreateWarmers(resource : Resource, screenCenter : Vector2) -> Array[CanvasItem]:
	var warmers : Array[CanvasItem] = []
	if resource is Shader:
		var material : ShaderMaterial = ShaderMaterial.new()
		material.shader = resource as Shader
		warmers.push_back(CreateMaterialWarmer(material, screenCenter))
	elif resource is PackedScene:
		warmers = CreateSceneWarmers((resource as PackedScene).get_state(), screenCenter)
	return warmers

static func CreateMaterialWarmer(material : Material, screenCenter : Vector2) -> ColorRect:
	var warmer : ColorRect = ColorRect.new()
	warmer.material = material
	warmer.size = Vector2(16, 16)
	warmer.position = screenCenter - warmer.size / 2
	warmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warmer.self_modulate.a = 0.01
	RegisterMaterial(material)
	return warmer

static func CreateParticleWarmer(properties : Dictionary[StringName, Variant], screenCenter : Vector2) -> GPUParticles2D:
	var warmer : GPUParticles2D = GPUParticles2D.new()
	for property in properties:
		if property != &"script":
			warmer.set(property, properties[property])
	warmer.position = screenCenter - warmer.visibility_rect.get_center()
	warmer.visible = true
	warmer.one_shot = true
	warmer.self_modulate.a = 0.01
	RegisterMaterial(warmer.process_material)
	RegisterMaterial(warmer.material)
	return warmer

static func CreateSceneWarmers(sceneState : SceneState, screenCenter : Vector2) -> Array[CanvasItem]:
	var warmers : Array[CanvasItem] = []
	for nodeIdx in sceneState.get_node_count():
		var properties : Dictionary[StringName, Variant] = GetNodeProperties(sceneState, nodeIdx)
		var processMaterial : Material = properties.get(&"process_material", null)
		var canvasMaterial : Material = properties.get(&"material", null)
		var isParticle : bool = sceneState.get_node_type(nodeIdx) == &"GPUParticles2D" or processMaterial != null
		if isParticle and not warmedMaterials.has(processMaterial):
			warmers.push_back(CreateParticleWarmer(properties, screenCenter))
		elif canvasMaterial and not warmedMaterials.has(canvasMaterial):
			warmers.push_back(CreateMaterialWarmer(canvasMaterial, screenCenter))
	return warmers

static func GetNodeProperties(sceneState : SceneState, nodeIdx : int) -> Dictionary[StringName, Variant]:
	var properties : Dictionary[StringName, Variant] = {}
	for propertyIdx in sceneState.get_node_property_count(nodeIdx):
		properties[sceneState.get_node_property_name(nodeIdx, propertyIdx)] = sceneState.get_node_property_value(nodeIdx, propertyIdx)
	return properties
