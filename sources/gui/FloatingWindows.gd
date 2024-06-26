extends Control

@onready var prevSize				= size

#
func MoveWindow(window : WindowPanel):
	move_child(window, get_child_count() - 1)

func ClearWindowsModifier():
	for window in get_children():
		window.ResetWindowModifier()

#
func _ready():
	prevSize = size
	for window in get_children():
		window.MoveFloatingWindowToTop.connect(self.MoveWindow)

func _on_window_resized():
	var overallRatio = Vector2.ONE
	if prevSize != null and prevSize.x != 0 and prevSize.y != 0:
		overallRatio = size / prevSize
	prevSize = size

	for child in get_children():
		if overallRatio != Vector2.ONE:
			child.set_position(child.get_position() * overallRatio)
		child.ClampToMargin(get_size())
