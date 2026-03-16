extends Marker2D
class_name LightSource

#
@onready var randomSeed : int = randi()
@export var color : Color = Color("#FFD28D")
@export var radius : int = 128
@export_range (0.0, 100.0) var speed : float = 20.0
@export var rescale : float = 1.0

#
var currentRadius : int = 128

#
func _ready():
	if Effects.lightLayer:
		radius = int(radius * (1 - Effects.lightLayer.intensity) * (2.5 + Effects.lightLayer.intensity))
	currentRadius = int(radius * rescale)

func _enter_tree():
	if Effects.lightLayer:
		Effects.lightLayer.RegisterLight(self)

func _exit_tree():
	if Effects.lightLayer:
		Effects.lightLayer.UnregisterLight(self)
