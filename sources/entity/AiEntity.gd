extends BaseEntity
class_name AiEntity

var AITimer : Timer	= null


func StartAITimer(delay : float, callable: Callable, map : Object):
	AITimer.start(delay)
	if not AITimer.timeout.is_connected(callable):
		AITimer.timeout.connect(callable.bind(self, map))


func _ready():
	_setup_nav_agent()
	
	if interactive:
		interactive.Setup(self, false)

	if AITimer == null:
		AITimer = Timer.new()
		AITimer.set_name("AITimer")
		add_child(AITimer)
