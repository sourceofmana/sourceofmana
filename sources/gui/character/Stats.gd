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

#
func _unhandled_input(event : InputEvent):
	if visible:
		if previousButton and previousButton.is_visible() and event.is_action("ui_left"):
			if Launcher.Action.TryPressed(event, "ui_left", true):
				previousButton.pressed.emit()
		elif nextButton and nextButton.is_visible() and event.is_action("ui_right"):
			if Launcher.Action.TryPressed(event, "ui_right", true):
				nextButton.pressed.emit()
