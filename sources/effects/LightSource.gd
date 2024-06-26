extends Marker2D
class_name LightSource

#
@onready var randomSeed : int = randi()
@export var color : Color = Color("#FFD28D")
@export var radius : int = 128
@export_range (0.0, 100.0) var speed : float = 20.0
@export var rescale : float = 1.0

#
var currentDeadband : float = 0.0
var currentRadius : int = 128

#
func _ready():
	add_to_group("lights")

	if Effects.lightLayer:
		radius = radius * (1 - Effects.lightLayer.lightLevel) * (2.5 + Effects.lightLayer.lightLevel)

func _physics_process(_delta):
	currentRadius = int(radius * rescale)
