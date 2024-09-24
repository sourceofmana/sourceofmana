extends ServiceBase

var correctPos : ColorRect					= null
var wrongPos : ColorRect					= null

var desyncDebug : bool						= false

#
func OnPlayerEnterGame():
	if desyncDebug:
		assert(Launcher.Player != null, "Debug: Player is not accessible")
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
