extends Object
class_name UICommons

#
const LightTextColor : Color 						= Color("FFFFDD")
const TextColor : Color 							= Color("EED8A1")
const DarkTextColor : Color							= Color("C19747")

const ContextAction : PackedScene					= preload("res://presets/gui/contexts/ContextAction.tscn")

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
