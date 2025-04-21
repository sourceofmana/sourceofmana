extends Node2D
class_name Projectile

#
@export var canRotate : bool				= false

var origin : Vector2					= Vector2.ZERO
var destination : Vector2				= Vector2.ZERO
var delay : float						= 0.0
var elapsed : float						= 0.0
var fade : float						= 0.15
var light : LightSource					= null

#
func _physics_process(delta):
	elapsed = min(delay, elapsed + delta)

	if elapsed == delay:
		Util.RemoveNode(self, get_parent())
	else:
		var scaleRatio : float = Util.FadeInOutRatio(elapsed, delay, fade, fade)
		if light:
			light.rescale = scaleRatio
		scale = lerp(Vector2.ZERO, Vector2.ONE, scaleRatio)
		global_position = lerp(origin, destination, elapsed / delay)

func _ready():
	if has_node("LightSource"):
		light = get_node("LightSource")
	if canRotate:
		rotation = origin.angle_to_point(destination)
	set("set_speed_scale", delay)
