tool
extends Area2D

export var destinationMap : String 			= ""
export var destinationPos : Vector2			= Vector2.ZERO

#
func _on_body_entered(body):
	if body && body is KinematicBody2D:
		Launcher.Map.Warp(self, destinationMap, destinationPos, body)

#
func _init():
	collision_layer = 2
	collision_mask = 2

func _ready():
	connect('body_entered', self, '_on_body_entered')
