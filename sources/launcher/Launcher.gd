extends Node

# High-prio services
var Root : Node						= null

# Specific services
var Action : ServiceBase			= null
var Scene : Node2D					= null
var GUI : ServiceBase				= null
var Debug : ServiceBase				= null

# Low-prio services
var Audio : ServiceBase				= null
var Camera : ServiceBase			= null
var Conf : ServiceBase				= null
var DB : ServiceBase				= null
var FSM : ServiceBase				= null
var Map : ServiceBase				= null
var Save : ServiceBase				= null
var Settings : ServiceBase			= null
var World : ServiceBase				= null
var Network : ServiceBase			= null

# Accessors
var Player : PlayerEntity			= null


#
func ParseLaunchMode():
	var launchClient : bool = Conf.GetBool("Default", "launchClient", Launcher.Conf.Type.PROJECT)
	var launchServer : bool = Conf.GetBool("Default", "launchServer", Launcher.Conf.Type.PROJECT)

	if "--hybrid" in OS.get_cmdline_args():
		launchClient = true
		launchServer = true
	elif "--client" in OS.get_cmdline_args():
		launchClient = true
		launchServer = false
	elif "--server" in OS.get_cmdline_args():
		launchClient = false
		launchServer = true

	LaunchMode(launchClient, launchServer)

func LaunchMode(isClient : bool = false, isServer : bool = false):
	Network.NetMode(isClient, isServer)
	if isClient:	LaunchClient()
	if isServer:	LaunchServer()

	_post_launch()

	if isServer:
		if not isClient:
			Scene.queue_free()
			FSM.queue_free()

			# TODO: add a GUI to display various server stats
			var l = Label.new()
			l.text = "Server mode started, to hide this window run this binary from the terminal as follow: ./path/to/source_of_mana --headless --server"
			add_child(l)

		Network.NetCreate()

func LaunchClient():
	if OS.is_debug_build():
		Debug		= FileSystem.LoadSource("debug/Debug.gd")

	# Load then low-prio services on which the order is not important
	Audio			= FileSystem.LoadSource("audio/Audio.gd")
	Camera			= FileSystem.LoadSource("camera/Camera.gd")
	Map				= FileSystem.LoadSource("map/Map.gd")
	Settings		= FileSystem.LoadSource("settings/Settings.gd")

func LaunchServer():
	World			= FileSystem.LoadSource("world/World.gd")
	add_child(World)

#
func _enter_tree():
	Root			= get_tree().get_root()
	Scene			= Root.get_node("Source")
	GUI				= Scene.get_node("CanvasLayer")

	if not Root or not Scene or not GUI:
		printerr("Could not initialize source's base services")
		_quit()

func _ready():
	Action			= FileSystem.LoadSource("action/Action.gd")
	Conf			= FileSystem.LoadSource("conf/Conf.gd")
	DB				= FileSystem.LoadSource("db/DB.gd")
	Network			= FileSystem.LoadSource("network/Network.gd")
	FSM				= FileSystem.LoadSource("launcher/FSM.gd")

	add_child(Action)
	add_child(Network)
	add_child(FSM)

	_post_launch()
	ParseLaunchMode()

# Call _post_launch functions for service depending on other services
func _post_launch():
	if Camera and not Camera.isInitialized:		Camera._post_launch()
	if GUI and not GUI.isInitialized:			GUI._post_launch()
	if Debug and not Debug.isInitialized:		Debug._post_launch()
	if Audio and not Audio.isInitialized:		Audio._post_launch()
	if Conf and not Conf.isInitialized:			Conf._post_launch()
	if DB and not DB.isInitialized:				DB._post_launch()
	if World and not World.isInitialized:		World._post_launch()
	if Settings and not Settings.isInitialized:	Settings._post_launch()
	if FSM and not FSM.isInitialized:			FSM._post_launch()

func _quit():
	get_tree().quit()
