extends BaseItem
class_name FoodItem

@export var HealthPoints : int = 4

func use():
	Launcher.Entities.playerEntity.stat.health = clamp(Launcher.Entities.playerEntity.stat.health + HealthPoints, 0, Launcher.Entities.playerEntity.stat.maxHealth)
