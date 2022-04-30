extends Node


var gameTitle			= "Source of Mana v0.1"
var DB					= load("res://sources/db/DB.gd").new()

func _process(_delta):
	OS.set_window_title(gameTitle + " | fps: " + str(Engine.get_frames_per_second()))

func _ready():
	# Load all services
	DB.Init()
