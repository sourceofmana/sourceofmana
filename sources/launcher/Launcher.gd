extends Node

# High-prio services
var Path				= null
var FileSystem			= null
var Util				= null
# Specific services
var World				= null
var GUI					= null
var Debug				= null
# Low-prio services
var Audio				= null
var Camera				= null
var Conf				= null
var DB					= null
var Entities			= null
var FSM					= null
var Map					= null
var Save				= null

#
func _init():
	# Load all high-prio services, order should not be important
	Path			= load("res://sources/system/Path.gd").new()
	FileSystem		= load("res://sources/system/FileSystem.gd").new()
	Util			= load("res://sources/util/Util.gd").new()

func _ready():
	# Load first low-prio services on which the order is important
	World			= get_tree().root.get_node("World")
	GUI				= World.get_node("CanvasLayer")

	if OS.is_debug_build():
		Debug		= FileSystem.LoadSource("debug/Debug.gd")

	# Load first low-prio services on which the order is not important
	Audio			= FileSystem.LoadSource("audio/Audio.gd")
	Camera			= FileSystem.LoadSource("camera/Camera.gd")
	Conf			= FileSystem.LoadSource("conf/Conf.gd")
	DB				= FileSystem.LoadSource("db/DB.gd")
	Entities		= FileSystem.LoadSource("entity/EntityManager.gd")
	FSM				= FileSystem.LoadSource("launcher/FSM.gd")
	Map				= FileSystem.LoadSource("map/Map.gd")

	# Call post_ready functions for service depending on other services
	if Debug:
		Debug._post_ready()
	Audio._post_ready()
	Conf._post_ready()
	DB._post_ready()
	FSM._post_ready()

func _process(delta : float):
	if Debug:
		Debug._process(delta)
