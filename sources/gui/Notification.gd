extends RichTextLabel

#
@export var modulateInScaler : float	 = 10.0
@export var modulateOutScaler : float	 = 2.0

@onready var timer : Timer			= $Timer
@onready var modulateWay : int		= 0

#
func AddNotification(notif : String, delay : float = 5.0):
	if notif.length() > 0 and delay > 0.0:
		ClearNotification()
		text = "[center]%s[/center]" % notif
		timer.start(delay)
		modulateWay = 1

func ClearNotification():
	if not timer.is_stopped():
		timer.stop()

	modulateWay = -1

#
func _on_timer_timeout():
	ClearNotification()

#
func _physics_process(delta):
	if modulateWay > 0 and modulate.a < 1.0:
		modulate.a = clampf(modulate.a + delta * modulateInScaler, 0.0, 1.0)
	elif modulateWay < 0 and modulate.a > 0.0:
		modulate.a = clampf(modulate.a - delta * modulateOutScaler, 0.0, 1.0)
	else:
		modulateWay = 0

func _ready():
	modulate.a = 0.0
