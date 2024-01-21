extends Node2D
class_name Projectile

#
var origin : Vector2					= Vector2.ZERO
var destination : Vector2				= Vector2.ZERO
var delay : float						= 0.0
var elapsed : float						= 0.0
var callable : Callable
var fade : float						= 0.15
@onready var light						= $LightSource

#
func _physics_process(delta):
	elapsed = min(delay, elapsed + delta)

	if elapsed == delay:
		if not callable.is_null() and callable.is_valid():
			callable.call()
		Util.RemoveNode(self, get_parent())
	else:
		var scaleRatio : float = Util.FadeInOutRatio(elapsed, delay, fade, fade)
		if light:
			light.rescale = scaleRatio
		scale = lerp(Vector2.ZERO, Vector2.ONE, scaleRatio)
		global_position = lerp(origin, destination, elapsed / delay)
