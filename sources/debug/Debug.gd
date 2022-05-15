extends Node

var projectName : String = ""

#
func _post_ready():
	projectName = Launcher.Conf.Project.get_value("Debug", "projectName")

func _process(_delta):

	OS.set_window_title(projectName + " | fps: " + str(Engine.get_frames_per_second()))
