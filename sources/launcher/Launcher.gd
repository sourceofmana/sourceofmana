extends Node

# High-prio services
var Root : Node						= null

# Specific services
var Action : ServiceBase			= null
var Scene : Node2D					= null
var Audio : AudioStreamPlayer		= null
var GUI : ServiceBase				= null
var Debug : ServiceBase				= null

# Low-prio services
var Camera : ServiceBase			= null
var FSM : ServiceBase				= null
var Map : ServiceBase				= null
var Save : ServiceBase				= null
var World : ServiceBase				= null
var SQL : ServiceBase				= null
var Network : ServiceBase			= null

# Accessors
var Player : Entity					= null


#
func ParseLaunchMode():
	var launchClient : bool = false
	var launchServer : bool = false

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
			Scene = null
			FSM.queue_free()
			FSM = null
			Action.queue_free()
			Action = null
			Audio.queue_free()
			Audio = null
			var label = FileSystem.LoadGui("Server")
			add_child.call_deferred(label)

func LaunchClient():
	if OS.is_debug_build():
		Debug		= FileSystem.LoadSource("debug/Debug.gd")

	# Load then low-prio services on which the order is not important
	Camera			= FileSystem.LoadSource("camera/Camera.gd")
	Map				= FileSystem.LoadSource("map/Map.gd")

func LaunchServer():
	World			= FileSystem.LoadSource("world/World.gd")
	SQL				= FileSystem.LoadSource("sql/SQL.gd")
	add_child.call_deferred(World)
	add_child.call_deferred(SQL)

func LauncherReset():
	if Debug:
		Debug.queue_free()
		Debug = null
	if Map:
		Map.UnloadMapNode()
		Map.queue_free()
		Map = null
	if Camera:
		Camera.Destroy()
		Camera.queue_free()
		Camera = null
	if Player:
		Player.queue_free()
		Player = null
	if World:
		World.Destroy()
		World.queue_free()
		World = null
	if SQL:
		SQL.Destroy()
		SQL.queue_free()
		SQL = null

#
func _enter_tree():
	Root			= get_tree().get_root()
	Scene			= Root.get_node("Source")
	GUI				= Scene.get_node("Canvas")
	Audio			= Scene.get_node("Audio")

	if not Root or not Scene or not GUI:
		printerr("Could not initialize source's base services")
		_quit()

func _ready():
	Action			= FileSystem.LoadSource("input/Action.gd")
	Network			= FileSystem.LoadSource("network/Network.gd")
	FSM				= FileSystem.LoadSource("launcher/FSM.gd")

	add_child.call_deferred(Action)
	add_child.call_deferred(Network)
	add_child.call_deferred(FSM)

	_post_launch()
	DB.Init()
	Conf.Init()

	ParseLaunchMode()

# Call _post_launch functions for service depending on other services
func _post_launch():
	if Camera and not Camera.isInitialized:		Camera._post_launch()
	if GUI and not GUI.isInitialized:			GUI._post_launch()
	if Debug and not Debug.isInitialized:		Debug._post_launch()
	if World and not World.isInitialized:		World._post_launch()
	if SQL and not SQL.isInitialized:			SQL._post_launch()
	if FSM and not FSM.isInitialized:			FSM._post_launch()
	if Network and not Network.isInitialized:	Network._post_launch()
	if Audio:									Audio._post_launch()

func _quit():
	LauncherReset()
	get_tree().quit()
