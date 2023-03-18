extends Timer
class_name AiTimer

#
func StartTimer(delay : float, callable: Callable):
	start(delay)
	if not timeout.is_connected(callable):
		timeout.connect(callable)

#
func _ready():
	set_name("AITimer")
