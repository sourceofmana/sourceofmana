extends Node

var minWindowSize		= Vector2(640, 480)
var gameTitle			= "Source of Mana v0.1"

var Path				= null
var World				= null
var DB					= null
var Audio				= null
var Map					= null

#
func _process(_delta):
	if OS.is_debug_build():
		OS.set_window_title(gameTitle + " | fps: " + str(Engine.get_frames_per_second()))

	OS.set_min_window_size(minWindowSize)

func _init():
	# Load all high-prio services
	Path = load("res://sources/system/Path.gd").new()

func _ready():
	World = get_tree().root.get_node("World")

	# Load all low-prio services
	DB = load("res://sources/db/DB.gd").new()
	Audio = load("res://sources/audio/Audio.gd").new()
	Map = load("res://sources/map/Map.gd").new()
