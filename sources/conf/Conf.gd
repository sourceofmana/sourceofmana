extends Node

var Project : ConfigFile				= Launcher.FileSystem.LoadConfig("project")
var Map : ConfigFile					= Launcher.FileSystem.LoadConfig("map")
var Window : ConfigFile					= Launcher.FileSystem.LoadConfig("window")

#
func _ready():
	if Window:
		OS.set_min_window_size(Window.get_value("PresetPC", "minWindowSize"))
