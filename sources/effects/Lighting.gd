extends CanvasLayer

#
@export var intensity : float					= 0.5

@onready var colorRect : ColorRect				= $ColorRect

var registeredLights : Array[LightSource]		= []
var lightDataBuffer : PackedVector4Array		= []
var colorDataBuffer : PackedColorArray			= []
var time : float								= 0.0

const MAX_LIGHTS : int							= 64

#
func _ready():
	colorRect.material.set_shader_parameter("light_level", intensity)
	lightDataBuffer.resize(MAX_LIGHTS)
	colorDataBuffer.resize(MAX_LIGHTS)

func RegisterLight(light : LightSource) -> void:
	if not registeredLights.has(light):
		registeredLights.append(light)

func UnregisterLight(light : LightSource) -> void:
	registeredLights.erase(light)

func _process(delta : float):
	if not visible or not Launcher.Camera.camera or not Launcher.Camera.camera.is_inside_tree():
		return

	var canvasTransform : Transform2D = Launcher.Camera.camera.get_canvas_transform()
	var canvasScale : Vector2 = canvasTransform.get_scale()

	var viewportSize : Vector2 = Launcher.Camera.camera.get_viewport_rect().size / canvasScale
	var cameraTopLeft : Vector2 = Launcher.Camera.camera.global_position - viewportSize * 0.5
	cameraTopLeft = cameraTopLeft.clamp(Vector2.ZERO, Launcher.Map.GetMapBoundaries() - viewportSize)
	var cameraRect : Rect2 = Rect2(cameraTopLeft, viewportSize)

	time += delta
	var lightCount : int = 0

	for light in registeredLights:
		if cameraRect.grow(light.currentRadius).has_point(light.global_position):
			var deadband : float = sin(light.speed * time + light.randomSeed) * 0.008 + 0.5 if light.speed > 0 else 0.5
			lightDataBuffer[lightCount] = Vector4(
				light.global_position.x * canvasScale.x,
				light.global_position.y * canvasScale.y,
				deadband,
				light.currentRadius * canvasScale.x
			)
			colorDataBuffer[lightCount] = light.color
			lightCount += 1
			if lightCount >= MAX_LIGHTS:
				break

	colorRect.material.set_shader_parameter("n_lights", lightCount)
	colorRect.material.set_shader_parameter("world_offset", -canvasTransform.origin)
	colorRect.material.set_shader_parameter("light_data", lightDataBuffer)
	colorRect.material.set_shader_parameter("color_data", colorDataBuffer)

func _enter_tree():
	visible = Effects.lightingEnabled
	Effects.lightLayer = self

func _exit_tree():
	Effects.lightLayer = null
