extends Node
class_name Util

#
static func Assert(condition : bool, message : String) -> void:
	if OS.is_debug_build() && not condition:
		printerr(message)
		push_warning(message)

static func PrintLog(logGroup : String, logString : String):
	print("[%d.%03d][%s] %s" % [Time.get_ticks_msec() / 1000.0, Time.get_ticks_msec() % 1000, logGroup, logString])

static func PrintInfo(_logGroup : String, _logString : String):
	pass
#	print("[%d.%03d][%s] %s" % [Time.get_ticks_msec() / 1000.0, Time.get_ticks_msec() % 1000, logGroup, logString])

#
static func RemoveCallback(objectSignal : Signal, callback : Callable):
	if objectSignal.is_connected(callback):
		objectSignal.disconnect(callback)

static func AddCallback(objectSignal : Signal, callback : Callable, args : Array):
	var callable : Callable = callback.bind(args) if callback == Util.ShootCallback else callback.bindv(args)
	objectSignal.connect(callable)

static func ShootCallback(args : Array):
	if args.size() > 0:
		var callback : Callable = args.pop_front()
		if callback:
			callback.callv(args)

#
static func OneShotCallback(objectSignal : Signal, callback : Callable, args : Array):
	RemoveCallback(objectSignal, Util.ShootCallback)
	AddCallback(objectSignal, Util.ShootCallback, [callback] + args)

#
static func SelfDestructCallback(parent : Node, timer : Timer, callback : Callable):
	if parent:
		parent.remove_child(timer)
		timer.queue_free()
	if not callback.is_null():
		callback.call()

static func SelfDestructTimer(parent : Node, delay : float, callback : Callable, timerName = "") -> Timer:
	if parent:
		var hasSpecialName : bool = timerName.length() > 0
		if not hasSpecialName or parent.get_node_or_null(timerName) == null:
			var timer : Timer = Timer.new()
			timer.one_shot = true
			timer.autostart = true
			timer.timeout.connect(Util.SelfDestructCallback.bind(parent, timer, callback))
			if hasSpecialName:
				timer.name = timerName
			parent.add_child(timer)
			timer.start(delay)
			return timer
	return null

#
static func RemoveNode(node : Node, parent : Node):
	if node != null:
		if parent != null:
			parent.remove_child(node)
		node.queue_free()

#
static func StartTimer(timer : Timer, delay : float, callable : Callable):
	if delay == 0.0:
		callable.call()
	elif timer:
		timer.start(delay)
		if timer.timeout.is_connected(callable):
			timer.timeout.disconnect(callable)
		timer.timeout.connect(callable)

static func LoopTimer(timer : Timer, delay : float):
	Assert(delay > 0, "Delay should never be null, infinite loop can happen on looped timers")
	if timer and delay > 0:
		timer.start(delay)

#
static func GetScreenCapture() -> Image:
	return Launcher.get_viewport().get_texture().get_image()

#
static func ColorToHSVA(color : Color) -> Vector4:
	var maxc : float = max(color.r, max(color.g, color.b))
	var minc : float = min(color.r, min(color.g, color.b))
	var delta : float = maxc - minc
	var h : float = 0.0
	var s : float = 0.0
	var v : float = maxc

	if delta > 0.00001:
		s = delta / maxc
	if color.r == maxc:
		h = (color.g - color.b) / delta + (6.0 if color.g < color.b else 0.0)
	elif color.g == maxc:
		h = (color.b - color.r) / delta + 2.0
	else:
		h = (color.r - color.g) / delta + 4.0

	h /= 6.0

	return Vector4(h, s, v, 1.0)

#
static func FadeInOutRatio(value : float, maxValue : float, fadeIn : float, fadeOut : float) -> float:
	var ratio : float = 1.0
	if value < fadeIn:
		ratio = min(value / fadeIn, ratio)
	if value > maxValue - fadeOut:
		ratio = min((fadeOut - (value - (maxValue - fadeOut))) / fadeOut, ratio)
	return ratio
