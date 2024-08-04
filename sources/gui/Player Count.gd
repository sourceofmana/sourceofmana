extends Label

func _ready():
	set_text("Current player count: 0")

func update():
	var playercount = Launcher.Network.Server.playerMap.values().size()
