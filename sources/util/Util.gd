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
static func RemoveNode(node : Node, parent : Node):
	if node != null:
		if parent != null:
			parent.remove_child(node)
		node.queue_free()

#
static func GetScreenCapture() -> Image:
	return Launcher.get_viewport().get_texture().get_image()

#
static func FadeInOutRatio(value : float, maxValue : float, fadeIn : float, fadeOut : float) -> float:
	var ratio : float = 1.0
	if value < fadeIn:
		ratio = min(value / fadeIn, ratio)
	if value > maxValue - fadeOut:
		ratio = min((fadeOut - (value - (maxValue - fadeOut))) / fadeOut, ratio)
	return ratio
