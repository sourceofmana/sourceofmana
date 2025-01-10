extends CanvasLayer

#
@onready var colorRectArrays : Array[ColorRect]	= [$GridContainer/HBoxContainer/ColorRect, $GridContainer/HBoxContainer/ColorRect2, $GridContainer/HBoxContainer/ColorRect3, $GridContainer/HBoxContainer/ColorRect4, $GridContainer/HBoxContainer2/ColorRect5, $GridContainer/HBoxContainer2/ColorRect6, $GridContainer/HBoxContainer2/ColorRect7, $GridContainer/HBoxContainer2/ColorRect8]
@export var lightLevel : float					= 0.5

var time : float								= 0.0
#
func _ready():
	for colorRect in colorRectArrays:
		colorRect.material.set_shader_parameter("light_level", lightLevel)

func _process(delta : float):
	if not visible or not Launcher.Camera.mainCamera or not Launcher.Camera.mainCamera.is_inside_tree():
		return

	var lights : Array[Node] = get_tree().get_nodes_in_group("lights")
	var visibleLights : Array[Node] = []

	var canvasTransform : Transform2D = Launcher.Camera.mainCamera.get_canvas_transform()
	var canvasScale : Vector2 = canvasTransform.get_scale()

	var viewportSize : Vector2 = Launcher.Camera.mainCamera.get_viewport_rect().size / canvasScale
	var cameraTopLeft : Vector2 = Launcher.Camera.mainCamera.global_position - viewportSize * 0.5
	cameraTopLeft = cameraTopLeft.clamp(Launcher.Camera.minPos, Launcher.Camera.maxPos - viewportSize)
	var cameraRect : Rect2 = Rect2(cameraTopLeft, viewportSize)

	time += delta
	for light in lights:
		if light and light is LightSource:
			if cameraRect.grow(light.currentRadius).has_point(light.global_position):
				light.currentDeadband = sin(light.speed * time + light.randomSeed) * 0.008 + 0.5 if light.speed > 0 else 0.5
				if light.currentDeadband > 0:
					visibleLights.append(light)

	for colorRect in colorRectArrays:
		var lightData : Array[Vector4] = []
		var colorData : Array[Color] = []
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
