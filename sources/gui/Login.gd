extends WindowPanel

@onready var nameText : LineEdit = $VBoxContainer/GridContainer/NameText

#
func _on_sign_in_pressed():
	SetFloatingWindowToTop()
	Launcher.GUI.CloseCurrentWindow()
	Launcher.FSM.ExitLogin(nameText.get_text())
