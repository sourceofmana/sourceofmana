tool
extends Area2D

export var destinationMap : String 			= ""
export var destinationPos : Vector2			= Vector2.ZERO

#
func Warp(body):
	if body is KinematicBody2D:
		if destinationMap.empty() == false:
			var mapReference = Launcher.DB.MapsDB[destinationMap]
			if mapReference:
				GlobalWorld.SetPlayerInWorld(Launcher.Path.MapRsc + mapReference._path, destinationPos)

#
func _ready():
	connect('body_entered', self, 'Warp')
