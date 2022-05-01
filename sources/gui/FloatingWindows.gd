extends Control

onready var prevSize				= rect_size

#
func MoveWindow(window):
	move_child(window, get_child_count() - 1)

#
func _ready():
	prevSize = rect_size
	for window in get_children():
		window.connect('MoveFloatingWindowToTop', self, 'MoveWindow')

func _on_window_resized():
	if prevSize != null:
		var overallRatio = Vector2.ONE
		if rect_size != Vector2.ZERO:
			overallRatio = rect_size / prevSize
		prevSize = rect_size

		if overallRatio != Vector2.ONE:
			for child in get_children():
				child.set_position(child.get_position() * overallRatio)
				child.set_size(child.get_size() * overallRatio)
