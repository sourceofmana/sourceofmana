extends ColorRect
class_name ItemTile

@onready var icon : TextureButton		= $Icon
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
		icon.set_texture_normal(cell.icon if cell else null)
	SetCountLabel(count)
	SetToolTip()
	set_visible(count > 0 and cell != null)

# Default
func _on_icon_button_up():
	if cell:
		cell.Use()

func _ready():
	visible = false
