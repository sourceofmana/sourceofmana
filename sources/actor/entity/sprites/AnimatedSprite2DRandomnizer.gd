extends AnimatedSprite2D


func _ready():
	frame = randi() % get_sprite_frames().get_frame_count(get_animation())


func _on_visibility_changed() -> void:
	print(visible)
	pass # Replace with function body.
