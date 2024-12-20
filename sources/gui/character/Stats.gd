extends PanelContainer

#
@onready var levelLabel : Label						= $Margin/VBox/Level/Value
@onready var locationLabel : Label					= $Margin/VBox/Location/Value
@onready var selection : Control					= $Margin/VBox/Selection
@onready var previousButton : Button				= $Margin/VBox/Selection/Previous
@onready var nextButton : Button					= $Margin/VBox/Selection/Next

#
func SetInfo(info : Dictionary):
	levelLabel.set_text(str(info["level"]))
	locationLabel.set_text(info["pos_map"])
