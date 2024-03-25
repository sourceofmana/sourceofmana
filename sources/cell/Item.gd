extends Cell
class_name Item

@export var HealthPoints : int = 4

func use():
	Launcher.Player.stat.SetHealth(HealthPoints)
