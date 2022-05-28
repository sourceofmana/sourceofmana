extends Node

var projectName : String = ""

#
func SetPlayerInventory(player : Node2D):
	player.inventory.items = Launcher.DB.ItemsDB

#
func _post_ready():
	projectName = Launcher.Conf.GetString("Default", "projectName", Launcher.Conf.Type.PROJECT)

func _process(_delta : float):
	OS.set_window_title(projectName + " | fps: " + str(Engine.get_frames_per_second()))
