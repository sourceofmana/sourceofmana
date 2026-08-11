extends Control

#
@onready var titleLabel : Label		= $TitleBar/Title

@export var titleText : String		= ""

#
func _ready():
	titleLabel.text = titleText

func _on_hide_button_pressed():
	var ancestor : WindowPanel = UICommons.GetWindowPanelAncestor(self)
	assert(ancestor, "Could not find a WindowPanel through ancestors of %s" % self.name)
	if ancestor:
		Launcher.GUI.ToggleControl(ancestor)
