extends Button

@onready var content : Control				= $ButtonContent
@onready var buttons : Control				= $ButtonContent/HBoxButtons

var progress_speed : float = 0.0
var is_playing : bool = false
var is_opening : bool = false

#
func _on_pressed():
	is_playing = true
	is_opening = !is_opening

	if is_opening and not buttons.is_visible():
		buttons.set_visible(true)

#
func _ready():
	Util.Assert(content != null and content.material != null and buttons != null, "Menu Indicator nodes are not set correctly")
	content.material.set_shader_parameter("progress", progress_speed)

func _process(delta):
	if is_playing:
		if is_opening:
			progress_speed += delta
			if progress_speed >= 1.0:
				progress_speed = 1.0
				is_playing = false
		else:
			progress_speed -= delta * 2.0
			if progress_speed <= 0.0:
				buttons.set_visible(false)
				progress_speed = 0.0
				is_playing = false
		if content.material:
			content.material.set_shader_parameter("progress", progress_speed)
