extends Control

@onready var content : Control				= $MenuContent
@onready var items : Control				= $MenuContent/HBoxItems
@onready var button : Button				= $MenuButton

var progress_speed : float = 0.0
var is_playing : bool = false
var is_opening : bool = false

#
func SetItemsVisible(toggle : bool):
	for w in items.get_children():
		w.set_visible(toggle)
		if w.targetWindow and not toggle:
			w.targetWindow.EnableControl(toggle)

#
func _on_button_pressed():
	is_playing = true
	is_opening = !is_opening

	if is_opening and not items.is_visible():
		items.set_visible(true)

#
func _ready():
	assert(content != null and content.material != null and items != null, "Menu Indicator nodes are not set correctly")
	content.material.set_shader_parameter("progress", progress_speed)
	items.set_visible(false)

func _process(delta : float):
	if is_playing:
		if is_opening:
			progress_speed += delta / 2.0
			if progress_speed >= 1.0:
				progress_speed = 1.0
				is_playing = false
		else:
			progress_speed -= delta
			if progress_speed <= 0.0:
				items.set_visible(false)
				progress_speed = 0.0
				is_playing = false
		if content.material:
			content.material.set_shader_parameter("progress", progress_speed)
