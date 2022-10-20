@tool
extends Area2D

@export var destinationMap : String 			= ""
@export var destinationPos : Vector2			= Vector2.ZERO

#
func bodyEntered(body):
	if body && body is CharacterBody2D:
		Launcher.Map.Warp(self, destinationMap, destinationPos, body)

#
func _init():
	collision_layer = 2
	collision_mask = 2

func _ready():
	var err = self.body_entered.connect(bodyEntered)
	Launcher.Util.Assert(err == OK, "Could not connect map warp signal")
