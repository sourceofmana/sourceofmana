extends CheckBox
class_name MenuLine

# Signal
signal line_checked
signal line_selected

# Variables
var id : int						= DB.UnknownHash

# Accessors
func Trigger():
	set_pressed(!is_pressed())
	line_checked.emit(id)

func Select():
	line_selected.emit(id)

func Enable(enable : bool):
	disabled = not enable

# Override
func _init(_id : int, labelName : String):
	button_mask = 0
	toggle_mode = true
	id = _id
	set_text(labelName)
	set_name(labelName)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				Trigger()
			elif event.pressed:
				Select()
