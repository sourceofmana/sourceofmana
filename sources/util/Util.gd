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
static func ReplaceCallback(objectSignal : Signal, callback : Callable, args : Array):
	if objectSignal.is_connected(callback):
		objectSignal.disconnect(callback)

	var callable : Callable = callback.bind(args) if callback == Util.ShootCallback else callback.bindv(args)
	objectSignal.connect(callable)

static func OneShotCallback(objectSignal : Signal, callback : Callable, args : Array):
	ReplaceCallback(objectSignal, Util.ShootCallback, [callback] + args)

static func ShootCallback(args : Array):
	if args.size() > 0:
		var callback : Callable = args.pop_front()
		if callback:
			callback.callv(args)

#
static func StartTimer(timer : Timer, delay : float, callable : Callable):
	if timer:
		timer.start(delay)
		if not timer.timeout.is_connected(callable):
			timer.timeout.connect(callable)

#
static func GetScreenCapture() -> Image:
	return Launcher.get_viewport().get_texture().get_image()

#
static func ColorToHSVA(color : Color) -> Vector4:
	var maxc = max(color.r, max(color.g, color.b))
	var minc = min(color.r, min(color.g, color.b))
	var delta = maxc - minc
	var h = 0.0
	var s = 0.0
	var v = maxc

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
