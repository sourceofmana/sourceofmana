extends Label

func OnPlayerCountChange(_rpcID):
	var playercount : int = Launcher.Network.Server.playerMap.values().size()
	set_text("Current player count: %d" % playercount)

func _ready():
	set_text("Current player count: 0")
	Launcher.Network.Server.player_connected.connect(OnPlayerCountChange)
	Launcher.Network.Server.player_disconnected.connect(OnPlayerCountChange)
