extends AiEntity
class_name MonsterEntity

# on dead drop whole inventory (some mobs like slimes can collect items)
# and also drop stuff from the drop table of that monster according to the drop chances

#
func _ready():
	super._ready()
