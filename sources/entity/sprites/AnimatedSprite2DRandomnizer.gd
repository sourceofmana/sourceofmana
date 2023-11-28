extends AnimatedSprite2D


func _ready():
	frame = randi() % get_sprite_frames().get_frame_count(get_animation())
