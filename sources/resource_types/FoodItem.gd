extends BaseItem
class_name FoodItem

@export var HealthPoints : int = 4

func use():
	Launcher.Player.stat.health = clamp(Launcher.Player.stat.health + HealthPoints, 0, Launcher.Player.stat.maxHealth)
