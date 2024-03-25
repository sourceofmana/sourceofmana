extends BaseItem
class_name FoodItem

@export var HealthPoints : int = 4

func use():
	Launcher.Player.stat.SetHealth(HealthPoints)
