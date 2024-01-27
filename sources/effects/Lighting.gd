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
	var lights : Array[Node]= get_tree().get_nodes_in_group("lights")
	var time : float = Time.get_ticks_msec() / 1000.0
	var cameraTopLeft : Vector2 = Launcher.Camera.mainCamera.get_target_position() - Launcher.Camera.mainCamera.get_viewport_rect().size / 2.0

	var updatedLights : Dictionary = {}

	for colorRect in colorRectArrays:
		var lightData : Array[Vector4] = []
		var colorData : Array[Color] = []

		for light in lights:
			if light and light is LightSource:
				if light.color == Color("FF00FF"):
					pass
				if Rect2( \
					Vector2(cameraTopLeft + colorRect.global_position - Vector2(light.currentRadius, light.currentRadius)), \
					Vector2(colorRect.size + Vector2(light.currentRadius, light.currentRadius) * 2) \
				).has_point(light.global_position):
					if not updatedLights.has(light):
						updatedLights[light] = true
						light.currentOscillation = sin(light.speed * time + light.randomSeed)
					lightData.append(Vector4(light.global_position.x, light.global_position.y, light.currentOscillation, light.currentRadius))
					colorData.append(light.color)

		colorRect.material.set_shader_parameter("n_lights", lightData.size())
		colorRect.material.set_shader_parameter("light_data", lightData)
		colorRect.material.set_shader_parameter("color_data", colorData)

#
func _ready():
	for colorRect in colorRectArrays:
		colorRect.material.set_shader_parameter("light_level", lightLevel)

func _physics_process(_delta):
	UpdateTransform()
	UpdateTexture()

func _enter_tree():
	visible = Effects.lightingEnabled
	Effects.lightLayer = self

func _exit_tree():
	Effects.lightLayer = null
