@tool
extends Area2D

class_name WarpObject

@export var destinationMap : String 			= ""
@export var destinationPos : Vector2			= Vector2.ZERO
@export var polygon : PackedVector2Array 		= []

#
func bodyEntered(body):
	if body && body is CharacterBody2D:
		Launcher.Network.Client.SetWarp(Launcher.Map.mapNode.get_name(), destinationMap, destinationPos)
		Launcher.Map.ReplaceMapNode(destinationMap)
#
func _init():
	collision_layer = 2
	collision_mask = 2

	var err = self.body_entered.connect(bodyEntered)
	Launcher.Util.Assert(err == OK, "Could not connect to Area2D's body_entered signal")
