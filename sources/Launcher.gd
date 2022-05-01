extends Node

var minWindowSize		= Vector2(640, 480)
var gameTitle			= "Source of Mana v0.1"
var DB					= load("res://sources/db/DB.gd").new()

#
func _process(_delta):
	if OS.is_debug_build():
		OS.set_window_title(gameTitle + " | fps: " + str(Engine.get_frames_per_second()))

	OS.set_min_window_size(minWindowSize)

func _ready():
	# Load all services
	DB.Init()
