extends Control

@onready var prevSize				= size

var defaultOffsets : Dictionary		= {}

#
func MoveWindow(window : WindowPanel):
	move_child(window, get_child_count() - 1)

func ClearWindowsModifier():
	for window in get_children():
		window.ResetWindowModifier()

func ResetWindowsLayout():
	for window in get_children():
		if window is not WindowPanel or not defaultOffsets.has(window.get_name()):
			continue
		var offsets : Rect2 = defaultOffsets[window.get_name()]
		window.ResetWindowModifier()
		window.set_offset(SIDE_LEFT, offsets.position.x)
		window.set_offset(SIDE_TOP, offsets.position.y)
		window.set_offset(SIDE_RIGHT, offsets.position.x + offsets.size.x)
		window.set_offset(SIDE_BOTTOM, offsets.position.y + offsets.size.y)
		window.UpdateWindow()

func ScaleDefaultOffsets(window : WindowPanel, ratio : Vector2):
	var windowName : StringName = window.get_name()
	if defaultOffsets.has(windowName):
		var offsets : Rect2 = defaultOffsets[windowName]
		offsets.position *= ratio
		if window.allowAutomaticResize:
			offsets.size *= ratio
		defaultOffsets[windowName] = offsets

#
func _ready():
	prevSize = size
	for window in get_children():
		window.MoveFloatingWindowToTop.connect(self.MoveWindow)
		defaultOffsets[window.get_name()] = Rect2(window.offset_left, window.offset_top, window.offset_right - window.offset_left, window.offset_bottom - window.offset_top)

func _on_window_resized():
	var overallRatio = Vector2.ONE
	if prevSize != null and prevSize.x != 0 and prevSize.y != 0:
		overallRatio = size / prevSize
	prevSize = size

	for child in get_children():
		if child is not WindowPanel:
			assert(false, "Floating window node has non-WindowPanel defined as child")
			continue
		if not child.floating:
			continue
		if overallRatio != Vector2.ONE:
			child.set_position(child.get_position() * overallRatio)
			if child.allowAutomaticResize:
				child.set_size(child.get_size() * overallRatio)
			ScaleDefaultOffsets(child, overallRatio)
		child.ClampToMargin(get_size())
