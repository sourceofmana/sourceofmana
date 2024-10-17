extends Control

#
@export_range (0.1, 10.0) var speed : float		= 2.0
@onready var progress : TextureProgressBar		= $Progress
var currentTween : Tween						= create_tween()

#
func _on_visibility_changed() -> void:
	if visible and Launcher.GUI and Launcher.GUI.progressTimer:
		currentTween.set_loops(Launcher.GUI.progressTimer.time_left / speed)
		currentTween.tween_property(progress, "radial_initial_angle", 360, speed).from_current()
		currentTween.play()
		create_tween().set_parallel(true).tween_property(progress, "modulate:a", 1.0, speed).set_ease(Tween.EASE_IN)
	else:
		currentTween.stop()
		if progress:
			progress.modulate.a = 0

func _ready():
		progress.modulate.a = 0
