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
