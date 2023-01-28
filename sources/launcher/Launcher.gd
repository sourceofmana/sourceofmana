extends Node

# High-prio services
var Root				= null
var Path				= null
var FileSystem			= null
var Util				= null
# Specific services
var Scene				= null
var GUI					= null
var Debug				= null
# Low-prio services
var Action				= null
var Audio				= null
var Camera				= null
var Conf				= null
var DB					= null
var Player				= null
var FSM					= null
var Map					= null
var Save				= null
var Settings			= null
var World				= null

#
func RunClient():
	# Load first low-prio services on which the order is important
	Scene			= get_tree().root.get_node("Source")
	GUI				= Scene.get_node("CanvasLayer")

	if OS.is_debug_build():
		Debug		= FileSystem.LoadSource("debug/Debug.gd")

	# Load then low-prio services on which the order is not important
	Action			= FileSystem.LoadSource("action/Action.gd")
	Audio			= FileSystem.LoadSource("audio/Audio.gd")
	Camera			= FileSystem.LoadSource("camera/Camera.gd")
	FSM				= FileSystem.LoadSource("launcher/FSM.gd")
	Map				= FileSystem.LoadSource("map/Map.gd")
	Settings		= FileSystem.LoadSource("settings/Settings.gd")

func RunServer():
	if not Scene:
		Scene		= Root.get_node("Server")
	World			= FileSystem.LoadSource("world/World.gd")

#
# Load all high-prio services, order should not be important
func _init():
	Path			= load("res://sources/system/Path.gd").new()
	FileSystem		= load("res://sources/system/FileSystem.gd").new()
	Util			= load("res://sources/util/Util.gd").new()

func _enter_tree():
	Root			= get_tree().get_root()
	if not Root or not Path or not FileSystem or not Util:
		printerr("Could not initialize source's base services")
		_quit()

func _ready():
	Conf			= FileSystem.LoadSource("conf/Conf.gd")
	DB				= FileSystem.LoadSource("db/DB.gd")
	if Conf.GetBool("Default", "runClient", Launcher.Conf.Type.MAP):
		RunClient()
	if Conf.GetBool("Default", "runServer", Launcher.Conf.Type.MAP):
		RunServer()

	_post_ready()

# Call post_ready functions for service depending on other services
func _post_ready():
	if Debug:
		Debug._post_ready()
	if Audio:
		Audio._post_ready()
	if Conf:
		Conf._post_ready()
	if DB:
		DB._post_ready()
	if World:
		World._post_ready()
	if FSM:
		FSM._post_ready()
	if Settings:
		Settings._post_ready()

func _process(delta : float):
	if Debug:
		Debug._process(delta)
	if FSM:
		FSM._process(delta)
	if World:
		World._process(delta)

func _quit():
	get_tree().quit()
