extends Node
class_name Callback

static func RemoveCallback(objectSignal : Signal, callback : Callable):
	if objectSignal.is_connected(callback):
		objectSignal.disconnect(callback)

static func AddCallback(objectSignal : Signal, callback : Callable, args : Array):
	var callable : Callable = callback.bind(args) if callback == Callback.ShootCallback else callback.bindv(args)
	objectSignal.connect(callable)

static func ShootCallback(args : Array):
	if args.size() > 0:
		var callback : Callable = args.pop_front()
		if callback:
			callback.callv(args)

static func PlugCallback(objectSignal : Signal, callback : Callable, args : Array = []):
	RemoveCallback(objectSignal, callback)
	AddCallback(objectSignal, callback, args)

#
static func OneShotCallback(objectSignal : Signal, callback : Callable, args : Array):
	RemoveCallback(objectSignal, Callback.ShootCallback)
	AddCallback(objectSignal, Callback.ShootCallback, [callback] + args)

#
static func SelfDestructCallback(parent : Node, timer : Timer, callback : Callable):
	if parent:
		parent.remove_child(timer)
		timer.queue_free()
	if not callback.is_null():
		callback.call()

#
static func SelfDestructTimer(parent : Node, delay : float, callback : Callable, timerName = "") -> Timer:
	if parent:
		var timer : Timer = null if timerName.is_empty() else parent.get_node_or_null(timerName)
		if not timer:
			timer = Timer.new()
			timer.one_shot = true
			timer.autostart = true
			timer.timeout.connect(Callback.SelfDestructCallback.bind(parent, timer, callback))
			if not timerName.is_empty():
				timer.name = timerName
			parent.add_child(timer)
		timer.start(delay)
		return timer
	return null

#
static func ResetTimer(timer : Timer, delay : float, callable : Callable):
	ClearTimer(timer)
	StartTimer(timer, delay, callable)

static func ClearTimer(timer : Timer):
	if timer:
		for sig in timer.get_signal_list():
			for connection in timer.get_signal_connection_list(sig["name"]):
				Callback.RemoveCallback(timer.get(sig["name"]), connection["callable"])
		timer.stop()

static func StartTimer(timer : Timer, delay : float, callable : Callable):
	if delay == 0.0:
		callable.call()
	elif timer:
		timer.start(delay)
		timer.set_autostart(true)
		if timer.timeout.is_connected(callable):
			timer.timeout.disconnect(callable)
		timer.timeout.connect(callable)

static func LoopTimer(timer : Timer, delay : float):
	Util.Assert(delay > 0, "Delay should never be null, infinite loop can happen on looped timers")
	if timer and delay > 0:
		timer.start(delay)
