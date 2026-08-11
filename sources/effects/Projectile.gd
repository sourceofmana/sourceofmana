extends Node2D
class_name Projectile

#
@export var canRotate : bool			= false

var origin : Vector2					= Vector2.ZERO
var destination : Vector2				= Vector2.ZERO
var delay : float						= 0.0
var fade : float						= 0.15
var light : LightSource					= null

#
func _ready():
	if has_node("LightSource"):
		light = get_node("LightSource")
	if canRotate:
		rotation = origin.angle_to_point(destination)
	if delay <= 0.0:
		return

	scale = Vector2.ZERO
	global_position = origin

	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", destination, delay).from(origin)
	tween.tween_method(UpdateScale, 0.0, delay, delay)
	tween.set_parallel(false)
	tween.tween_callback(Util.RemoveNode.bind(self, get_parent()))

#
func UpdateScale(elapsed : float) -> void:
	var scaleRatio : float = Util.FadeInOutRatio(elapsed, delay, fade, fade)
	if light:
		light.rescale = scaleRatio
	scale = lerp(Vector2.ZERO, Vector2.ONE, scaleRatio)
