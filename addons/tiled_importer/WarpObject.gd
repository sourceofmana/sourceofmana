@tool
extends Area2D
class_name WarpObject

@export var destinationMap : String 			= ""
@export var destinationPos : Vector2			= Vector2.ZERO
@export var polygon : PackedVector2Array 		= []
@export var autoWarp : bool						= true
@export var areaSize : float					= 1.0
@export var randomPoints : PackedVector2Array	= []

var hasPlayerWithin : bool						= false
var contextDisplayed : bool						= false

const defaultParticlesCount : int				= 12
const WarpFx : PackedScene						= preload("res://presets/effects/particles/WarpLocation.tscn")

#
func bodyEntered(body : CollisionObject2D):
	if body and body == Launcher.Player:
		hasPlayerWithin = true

func bodyExited(body : CollisionObject2D):
	if body and body == Launcher.Player:
		hasPlayerWithin = false
		HideLabel()

func getDestinationPos(_actor : Actor) -> Vector2:
	return destinationPos

func _physics_process(_delta):
	if hasPlayerWithin:
		var newPos : Vector2 = Launcher.Player.get_global_position() + Launcher.Player.entityPosOffset
		var canWarp : bool = Geometry2D.is_point_in_polygon(newPos - get_global_position(), polygon)
		if autoWarp:
			if canWarp:
				ConfirmWarp()
		else:
			if canWarp and (not contextDisplayed or not Launcher.GUI.choiceContext.is_visible()):
				DisplayLabel()
			elif not canWarp and contextDisplayed:
				HideLabel()

func ConfirmWarp():
	Network.TriggerWarp()

func DisplayLabel():
	Launcher.GUI.choiceContext.Clear()
	Launcher.GUI.choiceContext.Push(ContextData.new("gp_interact", destinationMap, ConfirmWarp.bind()))
	Launcher.GUI.choiceContext.FadeIn()
	contextDisplayed = true

func HideLabel():
	Launcher.GUI.choiceContext.FadeOut()
	contextDisplayed = false

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
