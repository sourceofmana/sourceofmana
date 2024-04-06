extends ColorRect
class_name ItemTile

@export var draggable : bool			= false
@onready var icon : TextureRect			= $Icon
@onready var label : Label				= $Label
var cell : BaseCell						= null

# Private
func SetToolTip():
	if icon:
		var tooltip : String = ""
		if cell:
			tooltip = cell.name
			if cell.description:
				tooltip += "\n" + cell.description
			if cell.weight == 0:
				tooltip += "\n\nWeight: " + str(cell.weight) + "g"
		icon.set_tooltip_text(tooltip)

func SetCountLabel(count : int):
	if label:
		if count >= 1000:
			label.text = "999+"
		elif count <= 1:
			label.text = ""
		else:
			label.text = str(count)

# Public
func SetData(sourceCell : BaseCell, count : int = 1):
	cell = sourceCell
	if icon:
		icon.set_texture(cell.icon if cell else null)
	SetCountLabel(count)
	SetToolTip()
	set_visible(count > 0 and cell != null)

func UseCell():
	if cell:
		cell.Use()

# Drag
func _get_drag_data(_position : Vector2):
	if cell and cell.usable:
		if icon:
			set_drag_preview(icon.duplicate())
		return cell
	return null

func _can_drop_data(_at_position : Vector2, data):
	return draggable and data is BaseCell and data != cell and data.usable

func _drop_data(_at_position : Vector2, data):
	SetData(data)

# Default
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			UseCell()
