@tool
extends Area2D
class_name WarpObject

@export var destinationMap : String 			= ""
@export var destinationPos : Vector2			= Vector2.ZERO
@export var polygon : PackedVector2Array 		= []
@export var autoWarp : bool						= true
@export var areaSize : float					= 1.0
@export var randomPoints : PackedVector2Array	= []

var currentTip : RichTextLabel					= null
var hasPlayerWithin : bool						= false
var lastPlayerPos : Vector2						= Vector2.ZERO

const defaultParticlesCount : int				= 12
const WarpFx : PackedScene						= preload("res://presets/effects/particles/WarpLocation.tscn")
const WarpTip : PackedScene						= preload("res://presets/gui/WarpTip.tscn")

#
func bodyEntered(body : CollisionObject2D):
	if body and body == Launcher.Player:
		hasPlayerWithin = true

func bodyExited(body : CollisionObject2D):
	if body and body == Launcher.Player:
		hasPlayerWithin = false
		lastPlayerPos = Vector2.ZERO
		HideLabel()

func getDestinationPos(_actor : Actor) -> Vector2:
	return destinationPos

func _physics_process(_delta):
	if hasPlayerWithin:
		var newPos : Vector2 = Launcher.Player.get_global_position()
		if lastPlayerPos != newPos:
			lastPlayerPos = newPos
			var canWarp : bool = Geometry2D.is_point_in_polygon(newPos - get_global_position(), polygon)

			if autoWarp:
				if canWarp:
					ConfirmWarp()
			else:
				if canWarp:
					DisplayLabel()
				else:
					HideLabel()

func _input(event):
	if not currentTip or not currentTip.visible:
		return

	for tip in currentTip.get_children():
		if tip and tip is ButtonTip and event.is_action_pressed(tip.action):
			ConfirmWarp()
			Launcher.Action.ConsumeAction(tip.action)
			get_viewport().set_input_as_handled()
			return

func ConfirmWarp():
	Launcher.Network.TriggerWarp()

func DisplayLabel():
	if not currentTip:
		currentTip = WarpTip.instantiate()
		currentTip.set_text(destinationMap)

		var xmin : float = INF
		var xmax : float = -INF
		for point in polygon:
			if point.x < xmin:
				xmin = point.x
			elif point.x > xmax:
				xmax = point.x
		currentTip.position.x += (xmax + xmin) / 2

		add_child(currentTip)

	if currentTip:
		currentTip.set_visible(true)

func HideLabel():
	if currentTip:
		currentTip.set_visible(false)

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
