@tool
extends Area2D

@export var destinationMap : String 			= ""
@export var destinationPos : Vector2			= Vector2.ZERO

#
func areaEntered(area):
	if area && area is KinematicCollision2D:
		Launcher.Map.Warp(self, destinationMap, destinationPos, area)

#
func _init():
	collision_layer = 2
	collision_mask = 2

func _ready():
	self.area_entered.connect(self.areaEntered)
