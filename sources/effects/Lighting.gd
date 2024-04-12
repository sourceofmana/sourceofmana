extends CanvasLayer

#
@onready var colorRectArrays : Array[ColorRect] = [$GridContainer/HBoxContainer/ColorRect, $GridContainer/HBoxContainer/ColorRect2, $GridContainer/HBoxContainer/ColorRect3, $GridContainer/HBoxContainer/ColorRect4, $GridContainer/HBoxContainer2/ColorRect5, $GridContainer/HBoxContainer2/ColorRect6, $GridContainer/HBoxContainer2/ColorRect7, $GridContainer/HBoxContainer2/ColorRect8]
@export var lightLevel : float = 0.5

#
func UpdateTransform():
	var canvas_transform : Transform2D = Launcher.Camera.mainCamera.get_canvas_transform()
	for colorRect in colorRectArrays:
		var topLeft = (-canvas_transform.origin + colorRect.global_position) / canvas_transform.get_scale()
		colorRect.material.set_shader_parameter("global_transform", Transform2D(0, topLeft))

func UpdateTexture():
	var lights : Array[Node] = get_tree().get_nodes_in_group("lights")
	var visibleLights : Array[Node] = []
	var time : float = Time.get_ticks_msec() / 1000.0
	var viewportSize : Vector2 = Launcher.Camera.mainCamera.get_viewport_rect().size
	var cameraTopLeft : Vector2 = Launcher.Camera.mainCamera.global_position - viewportSize * 0.5
	var cameraRect : Rect2 = Rect2(cameraTopLeft, viewportSize)

	for light in lights:
		if light and light is LightSource:
			if cameraRect.grow(light.currentRadius).has_point(light.global_position):
				light.currentDeadband = sin(light.speed * time + light.randomSeed) * 0.008 + 0.5 if light.speed > 0 else 0.5
				if light.currentDeadband > 0:
					visibleLights.append(light)

	for colorRect in colorRectArrays:
		var lightData : Array[Vector4] = []
		var colorData : Array[Color] = []

		for light in visibleLights:
			if Rect2( \
				Vector2(cameraTopLeft + colorRect.global_position), \
				Vector2(colorRect.size) \
			).grow(light.currentRadius).has_point(light.global_position):
					lightData.append(Vector4(light.global_position.x, light.global_position.y, light.currentDeadband, light.currentRadius))
					colorData.append(light.color)

		colorRect.material.set_shader_parameter("n_lights", lightData.size())
		colorRect.material.set_shader_parameter("light_data", lightData)
		colorRect.material.set_shader_parameter("color_data", colorData)

#
func _ready():
	for colorRect in colorRectArrays:
		colorRect.material.set_shader_parameter("light_level", lightLevel)

func _process(_delta : float):
	if visible and Launcher.Camera.mainCamera and Launcher.Camera.mainCamera.is_inside_tree():
		UpdateTransform()
		UpdateTexture()

func _enter_tree():
	visible = Effects.lightingEnabled
	Effects.lightLayer = self

func _exit_tree():
	Effects.lightLayer = null
