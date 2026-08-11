extends Button
class_name PlayerLine

#
signal line_selected(playerName : String)

#
func _init(playerName : String):
	text = playerName
	name = playerName
	flat = true
	toggle_mode = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	pressed.connect(func(): line_selected.emit(playerName))
