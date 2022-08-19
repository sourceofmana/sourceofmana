extends Node

var projectName : String = ""
var navLine : Line2D = null

#
func SetPlayerInventory(player : Node2D):
	player.inventory.items = Launcher.DB.ItemsDB

#
func _post_ready():
	projectName = Launcher.Conf.GetString("Default", "projectName", Launcher.Conf.Type.PROJECT)

	if Launcher.Conf.GetBool("NavLine", "enable", Launcher.Conf.Type.MAP):
		var lineWidth : float = Launcher.Conf.GetFloat("NavLine", "lineWidth", Launcher.Conf.Type.MAP)
		navLine = Line2D.new()
		navLine.set_name("NavigationLine")
		navLine.set_width(lineWidth)
		navLine.set_antialiased(true)
		Launcher.World.call_deferred("add_child", navLine)

func _process(_delta : float):
	DisplayServer.window_set_title(projectName + " | fps: " + str(Engine.get_frames_per_second()))

func UpdateNavLine():
	if navLine:
		navLine.points = Launcher.Entities.activePlayer.agent.get_nav_path()

func ClearNavLine():
	if navLine:
		navLine.points = []
