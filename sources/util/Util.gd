extends Node
class_name Util

#
static func Assert(condition : bool, message : String) -> void:
	if OS.is_debug_build() && not condition:
		printerr(message)
		push_warning(message)

static func PrintLog(logGroup : String, logString : String):
	print("[%d.%03d][%s] %s" % [Time.get_ticks_msec() / 1000.0, Time.get_ticks_msec() % 1000, logGroup, logString])

#
func ReplaceCallback(objectSignal : Signal, callback : Callable, args : Array):
	if objectSignal.is_connected(callback):
		objectSignal.disconnect(callback)

	var callable : Callable = callback.bind(args) if callback == ShootCallback else callback.bindv(args)
	objectSignal.connect(callable)

func OneShotCallback(objectSignal : Signal, callback : Callable, args : Array):
	ReplaceCallback(objectSignal, ShootCallback, [callback] + args)

func ShootCallback(args : Array):
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
func GetScreenCapture() -> Image:
	return Launcher.get_viewport().get_texture().get_image()

