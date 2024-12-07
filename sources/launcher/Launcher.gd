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
var World : ServiceBase				= null
var SQL : ServiceBase				= null
var Network : ServiceBase			= null

# Accessors
var Player : Entity					= null

# Signals
signal launchModeUpdated

#
func ParseLaunchMode():
	if "--server" in OS.get_cmdline_args():
		Scene.queue_free()
		GUI = null
		Audio = null

		Scene = FileSystem.LoadResource(Path.Pst + "Server" + Path.SceneExt)
		Root.add_child.call_deferred(Scene)

		LaunchMode(false, true)
	else:
		var emulateServer : bool = OS.get_name() == "Web" or OS.is_debug_build()
		LaunchMode(true, emulateServer)

func LaunchMode(launchClient : bool = false, launchServer : bool = false) -> bool:
	var isClientConnected : bool = Launcher.Network.Client != null
	var isServerConnected : bool = Launcher.Network.Server != null
	if isClientConnected == launchClient and isServerConnected == launchServer:
		return false

	Launcher.LauncherReset(false, false)
	Network.NetDestroy()
	if launchClient:	LaunchClient()
	if launchServer:	LaunchServer()
	Network.NetMode(launchClient, launchServer)

	_post_launch()
	launchModeUpdated.emit(launchClient, launchServer)
	return true

func LaunchClient():
	if OS.is_debug_build():
		Debug		= FileSystem.LoadSource("debug/Debug.gd")

	# Load then low-prio services on which the order is not important
	Action			= FileSystem.LoadSource("input/Action.gd")
	Camera			= FileSystem.LoadSource("camera/Camera.gd")
	Map				= FileSystem.LoadSource("map/Map.gd")
	Action.set_name("Action")

	add_child.call_deferred(Action)

func LaunchServer():
	World			= FileSystem.LoadSource("world/World.gd")
	SQL				= FileSystem.LoadSource("sql/SQL.gd")
	World.set_name("World")
	SQL.set_name("SQL")

	add_child.call_deferred(World)
	add_child.call_deferred(SQL)

func LauncherReset(clientStarted : bool, serverStarted : bool):
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

func LauncherQuit():
	if Network:
		Network.set_name("NetworkDestroyed")
		Network.NetDestroy()
		Network.queue_free()
		Network = null
	if FSM:
		FSM.set_name("FSMDestroyed")
		FSM.queue_free()
		FSM = null
	get_tree().quit()

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
	Network			= FileSystem.LoadSource("network/Network.gd")
	FSM				= FileSystem.LoadSource("launcher/FSM.gd")
	Network.set_name("Network")
	FSM.set_name("FSM")

	add_child.call_deferred(Network)
	add_child.call_deferred(FSM)

	DB.Init()
	Conf.Init()

	ParseLaunchMode()
	_post_launch()

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
	LauncherReset(false, false)
	LauncherQuit()
