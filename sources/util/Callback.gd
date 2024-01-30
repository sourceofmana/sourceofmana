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
		var hasSpecialName : bool = timerName.length() > 0
		if not hasSpecialName or parent.get_node_or_null(timerName) == null:
			var timer : Timer = Timer.new()
			timer.one_shot = true
			timer.autostart = true
			timer.timeout.connect(Callback.SelfDestructCallback.bind(parent, timer, callback))
			if hasSpecialName:
				timer.name = timerName
			parent.add_child(timer)
			timer.start(delay)
			return timer
	return null


#
static func ClearTimer(timer : Timer):
	if timer:
		for sig in timer.timeout.get_connections():
			Callback.RemoveCallback(timer.timeout, sig["callable"])
		timer.stop()

static func StartTimer(timer : Timer, delay : float, callable : Callable):
	if delay == 0.0:
		callable.call()
	elif timer:
		timer.start(delay)
		if timer.timeout.is_connected(callable):
			timer.timeout.disconnect(callable)
		timer.timeout.connect(callable)

static func LoopTimer(timer : Timer, delay : float):
	Util.Assert(delay > 0, "Delay should never be null, infinite loop can happen on looped timers")
	if timer and delay > 0:
		timer.start(delay)