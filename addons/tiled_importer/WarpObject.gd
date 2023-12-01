@tool
extends Area2D

class_name WarpObject

@export var destinationMap : String 			= ""
@export var destinationPos : Vector2			= Vector2.ZERO
@export var polygon : PackedVector2Array 		= []

var isPlayerEntered : bool						= false

#
func bodyEntered(body : CollisionObject2D):
	if body and body is PlayerEntity and body == Launcher.Player:
		isPlayerEntered = true

func bodyExited(body : CollisionObject2D):
	if body and body is PlayerEntity and body == Launcher.Player:
		isPlayerEntered = false

func _physics_process(_delta):
	if isPlayerEntered:
		Launcher.Network.TriggerWarp()

#
func _ready():
	collision_mask = 2

	self.body_entered.connect(bodyEntered)
	self.body_exited.connect(bodyExited)
