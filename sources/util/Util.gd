extends Node
class_name Util

# Logging
static func PrintLog(logGroup : String, logString : String):
	print("[%d.%03d][%s] %s" % [Time.get_ticks_msec() / 1000.0, Time.get_ticks_msec() % 1000, logGroup, logString])

static func PrintInfo(_logGroup : String, _logString : String):
#	print("[%d.%03d][%s] %s" % [Time.get_ticks_msec() / 1000.0, Time.get_ticks_msec() % 1000, logGroup, logString])
	pass

# Node management
static func RemoveNode(node : Node, parent : Node):
	if node != null:
		if parent != null:
			parent.remove_child(node)
		node.queue_free()

# Screenshot
static func GetScreenCapture() -> Image:
	return Launcher.get_viewport().get_texture().get_image()

# Fade
static func FadeInOutRatio(value : float, maxValue : float, fadeIn : float, fadeOut : float) -> float:
	var ratio : float = 1.0
	if value < fadeIn:
		ratio = min(value / fadeIn, ratio)
	if value > maxValue - fadeOut:
		ratio = min((fadeOut - (value - (maxValue - fadeOut))) / fadeOut, ratio)
	return ratio

# Text
static func GetFormatedText(value : String, numberAfterComma : int = 0) -> String:
	var commaLocation : int = value.find(".")
	var charCounter : int = 0

	if commaLocation > 0:
		charCounter = commaLocation - 3
	else:
		charCounter = value.length() - 3

	while charCounter > 0:
		value = value.insert(charCounter, ",")
		charCounter = charCounter - 3

	commaLocation = value.find(".")
	if commaLocation == -1:
		commaLocation = value.length()
		if numberAfterComma > 0:
			value += "."

	if numberAfterComma > 0:
		for i in range(value.length() - 1, commaLocation + numberAfterComma):
			value += "0"
	else:
		value = value.substr(0, commaLocation)

	return value

# Dictionary
static func DicCheckOrAdd(dic : Dictionary, key : Variant, value : Variant):
	if not key in dic:
		dic[key] = value
	elif dic[key] == null:
		dic[key] = value
