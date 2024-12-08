extends Node

# Common singletons
var Root : Node						= null
var Scene : Node2D					= null

# Client services
var Action : ServiceBase			= null
var Audio : AudioStreamPlayer		= null
var GUI : ServiceBase				= null
var Debug : ServiceBase				= null
var Camera : ServiceBase			= null
var Map : ServiceBase				= null

# Server services
var World : ServiceBase				= null
var SQL : ServiceBase				= null

# Accessors
var Player : Entity					= null

# Signals
signal launchModeUpdated

#
func Mode(launchClient : bool = false, launchServer : bool = false) -> bool:
	var isClientConnected : bool = Network.Client != null
	var isServerConnected : bool = Network.Server != null
	if isClientConnected == launchClient and isServerConnected == launchServer:
		return false

	Launcher.Reset(false, false)
	Network.Destroy()
	if launchClient:	Client()
	if launchServer:	Server()
	Network.Mode(launchClient, launchServer)

	_post_launch()
	launchModeUpdated.emit(launchClient, launchServer)
	return true

func Client():
	if OS.is_debug_build():
		Debug		= FileSystem.LoadSource("debug/Debug.gd")

	# Load then low-prio services on which the order is not important
	Action			= FileSystem.LoadSource("input/Action.gd", "Action")
	Camera			= FileSystem.LoadSource("camera/Camera.gd")
	Map				= FileSystem.LoadSource("map/Map.gd")

	add_child.call_deferred(Action)

func Server():
	World			= FileSystem.LoadSource("world/World.gd", "World")
	SQL				= FileSystem.LoadSource("sql/SQL.gd", "SQL")

	add_child.call_deferred(World)
	add_child.call_deferred(SQL)

func Reset(clientStarted : bool, serverStarted : bool):
	if not clientStarted:
		if Debug:
			Debug.Destroy()
			Debug.queue_free()
			Debug = null
		if Action:
			Action.set_name("ActionDestroyed")
			Action.Destroy()
			Action.queue_free()
			Action = null
		if Camera:
			Camera.Destroy()
			Camera.queue_free()
			Camera = null
		if Map:
			Map.Destroy()
			Map.queue_free()
			Map = null
		if Player:
			Player.queue_free()
			Player = null

	if not serverStarted:
		if World:
			World.set_name("WorldDestroyed")
			World.Destroy()
			World.queue_free()
			World = null
		if SQL:
			SQL.set_name("SQLDestroyed")
			SQL.Destroy()
			SQL.queue_free()
			SQL = null

func Quit():
	Network.Destroy()
	get_tree().quit()

#
func _ready():
	var startClient : bool = false
	var startServer : bool = false

	Root = get_tree().get_root()

	if "--server" in OS.get_cmdline_args():
		Scene = FileSystem.LoadResource(Path.Pst + "Server" + Path.SceneExt)
		Root.add_child.call_deferred(Scene)
		startServer = true
	else:
		Scene = FileSystem.LoadResource(Path.Pst + "Client" + Path.SceneExt)
		Root.add_child.call_deferred(Scene)
		GUI = Scene.get_node("Canvas")
		Audio = Scene.get_node("Audio")
		startClient = true
		startServer = OS.get_name() == "Web" or OS.is_debug_build()

	if not Root or not Scene:
		printerr("Could not initialize source's base services")
		Quit()

	DB.Init()
	Conf.Init()
	Mode(startClient, startServer)
	await Scene.ready

	_post_launch()

# Call _post_launch functions for service depending on other services
func _post_launch():
	if Camera and not Camera.isInitialized:		Camera._post_launch()
	if GUI and not GUI.isInitialized:			GUI._post_launch()
	if Debug and not Debug.isInitialized:		Debug._post_launch()
	if World and not World.isInitialized:		World._post_launch()
	if SQL and not SQL.isInitialized:			SQL._post_launch()
	if Audio:									Audio._post_launch()

func _quit():
	Reset(false, false)
	Quit()
