extends Label

func _ready():
	set_text("Current player count: 0")
	Launcher.Network.Server.player_connected.connect(_update)
	Launcher.Network.Server.player_disconnected.connect(_update)

func _update():
	var playercount : int = Launcher.Network.Server.playerMap.values().size()
	set_text("Current player count: %d" % playercount)
