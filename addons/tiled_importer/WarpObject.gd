tool
extends Area2D

export var destinationMap : String 			= ""
export var destinationPos : Vector2			= Vector2.ZERO

#
func Warp(body):
	if body is KinematicBody2D:
		GlobalWorld.SetPlayerInWorld("res://data/maps/phatina/" + destinationMap + ".tmx", destinationPos)

#
func _ready():
	connect('body_entered', self, 'Warp')
