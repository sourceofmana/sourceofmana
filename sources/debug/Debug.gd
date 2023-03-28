extends Node

var projectName : String					= ""
var correctPos : ColorRect					= null
var wrongPos : ColorRect					= null

#
func OnPlayerEnterGame():
	if Launcher.Conf.GetBool("Navigation", "desyncDebug", Launcher.Conf.Type.DEBUG):
		Util.Assert(Launcher.Player != null, "Debug: Player is not accessible")
		if Launcher.Player:
			if Launcher.Player.sprite:
				Launcher.Player.sprite.set_visible(false)

			if correctPos == null:
				var col : ColorRect = ColorRect.new()
				col.size = Vector2(4,4)
				col.color = Color.GREEN
				col.top_level = true
				correctPos = col
				Launcher.Player.add_child(col)

			if wrongPos == null:
				var col : ColorRect = ColorRect.new()
				col.size = Vector2(4,4)
				col.color = Color.MAGENTA
				col.top_level = true
				wrongPos = col
				Launcher.Player.add_child(col)

	if Launcher.Conf.GetBool("Inventory", "inventoryFill", Launcher.Conf.Type.DEBUG):
		Util.Assert(Launcher.Player != null && Launcher.Player.inventory != null, "Debug: Player inventory is not accessible")
		if Launcher.Player && Launcher.Player.inventory:
			var inventory : Object = Launcher.Player.inventory
			inventory.add_item(load("res://data/items/apple.tres"), 14)
			inventory.add_item(load("res://data/items/pettys_key.tres"), 3)
			inventory.add_item(load("res://data/items/grumpys_key.tres"))
			inventory.add_item(load("res://data/items/hungrys_key.tres"), 2)

#
func UpdateNavLine(entity : BaseEntity):
	if Launcher.Conf.GetBool("Navigation", "lineDebug", Launcher.Conf.Type.DEBUG):
		if entity && entity.agent:
			if entity.has_node("NavigationLine") == false:
				var lineWidth : float = Launcher.Conf.GetFloat("Navigation", "lineWidth", Launcher.Conf.Type.DEBUG)
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
				Util.Assert(false, "Navigation Line2D can't be null, something went wrong")

func ClearNavLine(entity : BaseEntity):
	if entity:
		if entity.has_node("NavigationLine"):
			var entityNavLine : Line2D = entity.get_node("NavigationLine")
			entityNavLine.points = []

#
func _post_launch():
	projectName = Launcher.Conf.GetString("Default", "projectName", Launcher.Conf.Type.DEBUG)

	if Launcher.Map and not Launcher.FSM.enter_game.is_connected(OnPlayerEnterGame):
		Launcher.FSM.enter_game.connect(OnPlayerEnterGame)
