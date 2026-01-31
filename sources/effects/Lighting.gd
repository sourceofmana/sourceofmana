extends CanvasLayer

#
@export var intensity : float					= 0.5

@onready var gridContainer : GridContainer		= $GridContainer
@onready var lightingPreset : Node				= FileSystem.LoadEffect("Lighting", false)

var colorRectArrays : Array[ColorRect]			= []
var time : float								= 0.0
var rectCount : int								= 8

#
func _ready():
	for rectIdx in rectCount:
		var lighting : ColorRect = lightingPreset.instantiate()
		lighting.material.set_shader_parameter("light_level", intensity)
		colorRectArrays.push_back(lighting)
		gridContainer.add_child(lighting)

func _process(delta : float):
	if not visible or not Launcher.Camera.mainCamera or not Launcher.Camera.mainCamera.is_inside_tree():
		return

	var lights : Array[Node] = get_tree().get_nodes_in_group("lights")
	var visibleLights : Array[Node] = []

	var canvasTransform : Transform2D = Launcher.Camera.mainCamera.get_canvas_transform()
	var canvasScale : Vector2 = canvasTransform.get_scale()

	var viewportSize : Vector2 = Launcher.Camera.mainCamera.get_viewport_rect().size / canvasScale
	var cameraTopLeft : Vector2 = Launcher.Camera.mainCamera.global_position - viewportSize * 0.5
	cameraTopLeft = cameraTopLeft.clamp(Vector2.ZERO, Launcher.Map.GetMapBoundaries() - viewportSize)
	var cameraRect : Rect2 = Rect2(cameraTopLeft, viewportSize)

	time += delta
	for light in lights:
		if light and light is LightSource:
			if cameraRect.grow(light.currentRadius).has_point(light.global_position):
				light.currentDeadband = sin(light.speed * time + light.randomSeed) * 0.008 + 0.5 if light.speed > 0 else 0.5
				if light.currentDeadband > 0:
					visibleLights.append(light)

	for colorRect in colorRectArrays:
		var lightData : PackedVector4Array = []
		var colorData : PackedColorArray = []
		var rescaledRect : Vector2 = colorRect.global_position / canvasScale
		var rectTopLeft : Vector2 = rescaledRect - canvasTransform.origin
		var rect : Rect2 = Rect2(Vector2(rectTopLeft), 	Vector2(colorRect.size))

		for light in visibleLights:
			var rescaledPos : Vector2 = rescaledRect + (light.global_position - rescaledRect) * canvasScale
			var rescaledRadius : float = light.currentRadius * canvasScale.x
			if rect.grow(rescaledRadius).has_point(rescaledPos):
				lightData.append(Vector4(rescaledPos.x, rescaledPos.y, light.currentDeadband, rescaledRadius))
				colorData.append(light.color)

		colorRect.material.set_shader_parameter("global_transform", Transform2D(0, rectTopLeft))
		colorRect.material.set_shader_parameter("n_lights", lightData.size())
		colorRect.material.set_shader_parameter("light_data", lightData)
		colorRect.material.set_shader_parameter("color_data", colorData)

func _enter_tree():
	visible = Effects.lightingEnabled
	Effects.lightLayer = self

func _exit_tree():
	Effects.lightLayer = null
