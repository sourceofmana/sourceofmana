extends Node

# High-prio services
var Path				= null
var FileSystem			= null
var Util				= null
# Specific services
var World				= null
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
	Util			= load("res://sources/util/Util.gd").new()
	Path			= load("res://sources/system/Path.gd").new()
	FileSystem		= load("res://sources/system/FileSystem.gd").new()

func _ready():
	World			= get_tree().root.get_node("World")
	if OS.is_debug_build():
		Debug		= FileSystem.LoadSource("debug/Debug.gd")

	# Load all low-prio services, order should not be important
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
	Conf._post_ready()
	Entities._post_ready()
	DB._post_ready()
	FSM._post_ready()

func _process(delta : float):
	if Debug:
		Debug._process(delta)
