extends BaseEntity
class_name AiEntity

var AITimer : Timer	= null


func AddAITimer(delay : float, callable: Callable, map : Object):
	AITimer.stop()
	AITimer.start(delay)
	AITimer.autostart = true
	if not AITimer.timeout.is_connected(callable):
		AITimer.timeout.connect(callable.bind(self, map))


func _ready():
	_setup_nav_agent()
	
	if interactive:
		interactive.Setup(self, false)

	if AITimer == null:
		AITimer = Timer.new()
		AITimer.set_name("Timer")
		add_child(AITimer)
