extends ServiceBase

var correctPos : ColorRect					= null
var wrongPos : ColorRect					= null

var navLineDebug : bool						= false
var navlineWidth : int 						= 2
var desyncDebug : bool						= false

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

#
func UpdateNavLine(entity : Entity):
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

func ClearNavLine(entity : Entity):
	if entity:
		if entity.has_node("NavigationLine"):
			var entityNavLine : Line2D = entity.get_node("NavigationLine")
			entityNavLine.points = []

#
func _post_launch():
	if Launcher.Map and not Launcher.FSM.enter_game.is_connected(OnPlayerEnterGame):
		Launcher.FSM.enter_game.connect(OnPlayerEnterGame)

	isInitialized = true

func Refresh(_delta : float):
	if Launcher.Player:
		if correctPos:
			correctPos.position = Launcher.Player.position + Launcher.Player.entityPosOffset
		if wrongPos:
			wrongPos.position = Launcher.Player.position
