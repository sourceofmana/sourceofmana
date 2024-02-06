@tool
extends Area2D
class_name WarpObject

@export var destinationMap : String 			= ""
@export var destinationPos : Vector2			= Vector2.ZERO
@export var polygon : PackedVector2Array 		= []
@export var areaSize : float					= 1.0
@export var randomPoints : PackedVector2Array	= []

const defaultParticlesCount : int				= 12
var isPlayerEntered : bool						= false

static var WarpFx : PackedScene					= preload("res://presets/effects/particles/WarpLocation.tscn")

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

	var particle : CPUParticles2D = WarpFx.instantiate()
	particle.emission_shape = CPUParticles2D.EmissionShape.EMISSION_SHAPE_POINTS
	particle.emission_points = randomPoints
	add_child.call_deferred(particle)

	var areaRatio : float = areaSize / (32*32)
	particle.amount = int(float(defaultParticlesCount) * areaRatio)
