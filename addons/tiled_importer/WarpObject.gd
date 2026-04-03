@tool
extends Node2D
class_name WarpObject

@export var destinationID : int					= DB.UnknownHash
@export var polygon : PackedVector2Array 		= []
@export var areaSize : float					= 1.0
@export var randomPoints : PackedVector2Array	= []

#
var destinationPos : Vector2					= Vector2.ZERO
var autoWarp : bool								= true

const defaultParticlesCount : int				= 12
const WarpFx : PackedScene						= preload("res://presets/effects/particles/WarpLocation.tscn")

#
func _ready():
	var particle : GPUParticles2D = WarpFx.instantiate()

	if not randomPoints.is_empty():
		var image := Image.create(randomPoints.size(), 1, false, Image.FORMAT_RGBF)
		for i in range(randomPoints.size()):
			var point : Vector2 = randomPoints[i]
			image.set_pixel(i, 0, Color(point.x, point.y, 0.0))
		var mat : ParticleProcessMaterial = particle.process_material as ParticleProcessMaterial
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
		mat.emission_shape_scale = Vector3(1.0, 1.0, 1.0)
		mat.emission_point_count = randomPoints.size()
		mat.emission_point_texture = ImageTexture.create_from_image(image)

	var areaRatio : float = areaSize / (32*32)
	particle.amount = int(float(defaultParticlesCount) * areaRatio)
	add_child.call_deferred(particle)
