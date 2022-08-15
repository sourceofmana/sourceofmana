extends Panel

#
func _ready():
	pass

#
func _on_Yes_pressed():
	get_tree().quit()

func _on_No_pressed():
	set_visible(false)
