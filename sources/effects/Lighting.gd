extends CanvasLayer

#
@onready var colorRect : ColorRect = $ColorRect
@export var lightLevel : float = 0.5

var image = Image.create(128, 2, false, Image.FORMAT_RGBAH)
var imageTexture : ImageTexture = ImageTexture.new()

#
func UpdateTransform():
	var t = Transform2D(0, Vector2())
	if Launcher.Camera != null and Launcher.Camera.mainCamera != null:
		var canvas_transform = Launcher.Camera.mainCamera.get_canvas_transform()
		var top_left = -canvas_transform.origin / canvas_transform.get_scale()
		t = Transform2D(0, top_left)
	colorRect.material.set_shader_parameter("global_transform", t)

func UpdateTexture():
	if Launcher.Camera == null or Launcher.Camera.mainCamera == null:
		return

	var cameraCenter : Vector2 = Launcher.Camera.mainCamera.get_target_position()
	var viewportRadius : Vector2 = colorRect.get_viewport_rect().size / 2.0

	var lights = get_tree().get_nodes_in_group("lights")
	var lightData : Array[Vector4] = []
	var colorData : Array[Color] = []
	var time : float = Time.get_ticks_msec() / 1000.0

	for light in lights:
		if light and light is LightSource:
			if Rect2( \
				Vector2(cameraCenter - viewportRadius - Vector2(light.radius, light.radius) / 2), \
				Vector2(viewportRadius * 2 + Vector2(light.radius, light.radius)) \
			).has_point(light.global_position):
				var light_oscillation : float = sin(light.speed * time + light.randomSeed)
				lightData.append(Vector4(light.global_position.x, light.global_position.y, light_oscillation, light.radius))
				colorData.append(light.color)

	imageTexture.set_image(image)
	colorRect.material.set_shader_parameter("n_lights", lightData.size())
	colorRect.material.set_shader_parameter("light_data", lightData)
	colorRect.material.set_shader_parameter("color_data", colorData)
	colorRect.material.set_shader_parameter("light_level", lightLevel)

#
func _ready():
	imageTexture = ImageTexture.create_from_image(image)

func _physics_process(_delta):
	UpdateTransform()
	UpdateTexture()

func _enter_tree():
	visible = Effects.lightingEnabled
	Effects.lightLayer = self

func _exit_tree():
	Effects.lightLayer = null
