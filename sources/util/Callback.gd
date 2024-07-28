extends Node
class_name Callback

static func RemoveCallback(objectSignal : Signal, callback : Callable):
	if objectSignal.is_connected(callback):
		objectSignal.disconnect(callback)

static func AddCallback(objectSignal : Signal, callback : Callable, args : Array):
	var bundledCallback : Callable = callback.bind(args) if callback == Callback.ShootCallback else callback.bindv(args)
	objectSignal.connect(bundledCallback)

static func PlugCallback(objectSignal : Signal, callback : Callable, args : Array = []):
	RemoveCallback(objectSignal, callback)
	AddCallback(objectSignal, callback, args)

static func ShootCallback(args : Array):
	if args.size() > 0:
		TriggerCallback(args.pop_front(), args)

static func TriggerCallback(callback : Callable, args : Array = []):
	if callback and callback is Callable and not callback.is_null() and callback.is_valid():
		if args.size() == 0 and callback.get_bound_arguments_count() > 0:
			args = callback.get_bound_arguments()
		for arg in args:
			if arg and is_instance_valid(arg) and arg is Object and arg.is_queued_for_deletion():
				return
		callback.callv(args)

#
static func OneShotCallback(objectSignal : Signal, callback : Callable, args : Array = []):
	RemoveCallback(objectSignal, Callback.ShootCallback)
	AddCallback(objectSignal, Callback.ShootCallback, [callback] + args)

#
static func SelfDestructCallback(parent : Node, timer : Timer, callback : Callable):
	if parent:
		parent.remove_child(timer)
		timer.queue_free()
	TriggerCallback(callback)

#
static func SelfDestructTimer(parent : Node, delay : float, callback : Callable = Callable(), timerName = "") -> Timer:
	if delay <= 0.0:
		TriggerCallback(callback)
	elif parent:
		var timer : Timer = null if timerName.is_empty() else parent.get_node_or_null(timerName)
		if not timer:
			timer = Timer.new()
			timer.one_shot = true
			timer.autostart = true
			AddCallback(timer.timeout, Callback.SelfDestructCallback, [parent, timer, callback])
			if not timerName.is_empty():
				timer.name = timerName
			parent.add_child(timer)
		timer.start(delay)
		return timer
	return null

#
static func ResetTimer(timer : Timer, delay : float, callback : Callable):
	ClearTimer(timer)
	StartTimer(timer, delay, callback)

static func ClearTimer(timer : Timer):
	if timer:
		for sig in timer.get_signal_list():
			for connection in timer.get_signal_connection_list(sig["name"]):
				Callback.RemoveCallback(timer.get(sig["name"]), connection["callable"])
		timer.stop()

static func StartTimer(timer : Timer, delay : float, callback : Callable):
	if delay == 0.0:
		TriggerCallback(callback)
	elif timer:
		timer.start(delay)
		timer.set_autostart(true)
		PlugCallback(timer.timeout, callback)

static func LoopTimer(timer : Timer, delay : float):
	Util.Assert(delay > 0, "Delay should never be null, infinite loop can happen on looped timers")
	if timer and delay > 0:
		timer.start(delay)

static func Empty():
	pass
