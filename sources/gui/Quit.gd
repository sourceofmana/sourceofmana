extends Panel

onready var yesButton : Button = $VBoxContainer/HBoxContainer/Yes
onready var noButton : Button = $VBoxContainer/HBoxContainer/No

#
func _on_Yes_pressed():
	get_tree().quit()

func _on_No_pressed():
	set_visible(false)

func _on_Panel_draw():
	if yesButton:
		yesButton.grab_focus()
