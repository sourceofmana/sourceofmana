extends ServiceBase

var correctPos : ColorRect					= null
var wrongPos : ColorRect					= null

var navLineDebug : bool						= false
var navlineWidth : int 						= 2
var desyncDebug : bool						= false
var inventoryFill : bool					= true

#
func OnPlayerEnterGame():
	if desyncDebug:
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
				Launcher.Player.add_child.call_deferred(col)

			if wrongPos == null:
				var col : ColorRect = ColorRect.new()
				col.size = Vector2(4,4)
				col.color = Color.MAGENTA
				col.top_level = true
				wrongPos = col
				Launcher.Player.add_child.call_deferred(col)

	if  inventoryFill:
		Util.Assert(Launcher.Player != null && Launcher.Player.inventory != null, "Debug: Player inventory is not accessible")
		if Launcher.Player && Launcher.Player.inventory:
			ResourceLoader.load_threaded_request("res://data/items/apple.tres")
			ResourceLoader.load_threaded_request("res://data/items/pettys_key.tres")
			ResourceLoader.load_threaded_request("res://data/items/grumpys_key.tres")
			ResourceLoader.load_threaded_request("res://data/items/hungrys_key.tres")
			var inventory : Object = Launcher.Player.inventory
			inventory.add_item(ResourceLoader.load_threaded_get("res://data/items/apple.tres"), 14)
			inventory.add_item(ResourceLoader.load_threaded_get("res://data/items/pettys_key.tres"), 3)
			inventory.add_item(ResourceLoader.load_threaded_get("res://data/items/grumpys_key.tres"))
			inventory.add_item(ResourceLoader.load_threaded_get("res://data/items/hungrys_key.tres"), 2)

#
func UpdateNavLine(entity : BaseEntity):
	if navLineDebug:
		if entity and entity.agent:
			if not entity.has_node("NavigationLine"):
				var navLine : Line2D = Line2D.new()
				navLine.set_name("NavigationLine")
				navLine.set_width(navlineWidth)
				navLine.set_default_color(Color(Color.WHITE, 0.4))
				navLine.set_antialiased(true)
				navLine.set_as_top_level(true)
				entity.add_child.call_deferred(navLine)

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
	if Launcher.Map and not Launcher.FSM.enter_game.is_connected(OnPlayerEnterGame):
		Launcher.FSM.enter_game.connect(OnPlayerEnterGame)

	isInitialized = true
