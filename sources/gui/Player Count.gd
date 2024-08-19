extends Label

func _ready():
	set_text("Current player count: 0")

func update():
	var playercount : int = Launcher.Network.Server.playerMap.values().size()
