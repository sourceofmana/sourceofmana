extends Control

@onready var prevSize				= size

#
func MoveWindow(window):
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
	if prevSize != null:
		var overallRatio = Vector2.ONE
		if size != Vector2.ZERO:
			overallRatio = size / prevSize
		prevSize = size

		if overallRatio != Vector2.ONE:
			for child in get_children():
				child.set_position(child.get_position() * overallRatio)
				child.set_size(child.get_size() * overallRatio)
