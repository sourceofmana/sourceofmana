tool
extends Area2D

export var destinationMap : String 			= ""
export var destinationPos : Vector2			= Vector2.ZERO

#
func _init():
	collision_layer = 2
	collision_mask = 2

func _ready():
	connect('body_entered', Launcher.Map, 'Warp', [destinationMap, destinationPos])
