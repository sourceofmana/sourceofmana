extends PointLight2D

var value : float						= 0
var generalSpeed : float				= 10
var positionSpeed : float				= 2
var baseEnergy : float					= 0.9
var baseScale : float					= 0.9
var modulateEnergy : float				= 0.1
var modulateScale : float				= 0.1
var maxOffset : float					= 2

#
func _physics_process(delta):
	value += delta
	var sinValue = abs(sin(value * generalSpeed))

	energy			= baseEnergy + modulateEnergy * sinValue
	texture_scale	= baseScale + modulateScale * sinValue
	offset			= Vector2(sin(value * positionSpeed), cos(value * positionSpeed)) * maxOffset

func _ready():
	randomize()
	value = randf()

	baseEnergy	= energy * 0.97
	baseScale	= texture_scale * 0.99

	modulateEnergy	= energy - baseEnergy
	modulateScale	= texture_scale - baseScale
