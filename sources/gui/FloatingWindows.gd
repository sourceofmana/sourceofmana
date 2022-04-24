extends Control


func _ready():
	for window in get_children():
		window.connect('MoveFloatingWindowToTop', self, 'MoveWindow')

func MoveWindow(window):
	move_child(window, get_child_count() - 1)
