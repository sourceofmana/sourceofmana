extends Marker2D
class_name LightSource

@export var color : Color = Color("#FFD28D")
@export var radius : int = 128
@export_range (0.0, 100.0) var speed : float = 20.0

#
func _ready():
	add_to_group("lights")

	if Effects.lightLayer:
		radius = radius * (1 - Effects.lightLayer.lightLevel) * (2 + Effects.lightLayer.lightLevel)
