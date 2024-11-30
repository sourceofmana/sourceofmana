extends RichTextLabel

#
@export var modulateInScaler : float	 = 10.0
@export var modulateOutScaler : float	 = 2.0

@onready var timer : Timer				= $Timer

var way : UICommons.Way					= UICommons.Way.KEEP

#
func AddNotification(notif : String, delay : float = 5.0):
	ClearNotification()
	if notif.length() > 0 and delay > 0.0:
		text = "[center]%s[/center]" % notif
		timer.start(delay)
		way = UICommons.Way.SHOW

func ClearNotification():
	if not timer.is_stopped():
		timer.stop()

	way = UICommons.Way.HIDE

#
func _on_timer_timeout():
	ClearNotification()

#
func _physics_process(delta : float):
	if way == UICommons.Way.SHOW and modulate.a < 1.0:
		modulate.a = clampf(modulate.a + delta * modulateInScaler, 0.0, 1.0)
	elif way == UICommons.Way.HIDE and modulate.a > 0.0:
		modulate.a = clampf(modulate.a - delta * modulateOutScaler, 0.0, 1.0)
	else:
		way = UICommons.Way.KEEP

func _ready():
	modulate.a = 0.0
