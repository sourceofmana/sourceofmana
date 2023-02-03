extends Node

var projectName : String = ""

#
func SetPlayerInventory():
	Launcher.Util.Assert(Launcher.Player != null && Launcher.Player.inventory != null, "Debug: Player inventory is not accessible")
	if Launcher.Player && Launcher.Player.inventory:
		var inventory : Object = Launcher.Player.inventory
		inventory.add_item(load("res://data/items/apple.tres"), 14)
		inventory.add_item(load("res://data/items/pettys_key.tres"), 3)
		inventory.add_item(load("res://data/items/grumpys_key.tres"))
		inventory.add_item(load("res://data/items/hungrys_key.tres"), 2)

#
func _post_run():
	projectName = Launcher.Conf.GetString("Default", "projectName", Launcher.Conf.Type.PROJECT)

func _process(_delta : float):
	pass

#
func UpdateNavLine(entity : BaseEntity):
	if Launcher.Conf.GetBool("NavLine", "enable", Launcher.Conf.Type.MAP):
		if entity && entity.agent:
			if entity.has_node("NavigationLine") == false:
				var lineWidth : float = Launcher.Conf.GetFloat("NavLine", "lineWidth", Launcher.Conf.Type.MAP)
				var navLine : Line2D = Line2D.new()
				navLine.set_name("NavigationLine")
				navLine.set_width(lineWidth)
				navLine.set_default_color(Color(Color.WHITE, 0.4))
				navLine.set_antialiased(true)
				navLine.set_as_top_level(true)
				entity.add_child(navLine)

			if entity.has_node("NavigationLine"):
				var entityNavLine : Line2D = entity.get_node("NavigationLine")
				entityNavLine.points = entity.agent.get_current_navigation_path()
			else:
				Launcher.Util.Assert(false, "Navigation Line2D can't be null, something went wrong")

func ClearNavLine(entity : BaseEntity):
	if entity:
		if entity.has_node("NavigationLine"):
			var entityNavLine : Line2D = entity.get_node("NavigationLine")
			entityNavLine.points = []
