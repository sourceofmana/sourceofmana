extends Node

var gameTitle = "Source of Mana v0.1"

func _process(_delta):
	OS.set_window_title(gameTitle + " | fps: " + str(Engine.get_frames_per_second()))
