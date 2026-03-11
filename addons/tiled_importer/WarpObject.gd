@tool
extends Area2D
class_name WarpObject

@export var destinationID : int		 			= DB.UnknownHash
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
	if not Launcher.GUI.IsDialogueContextOpened():
		Launcher.GUI.choiceContext.Clear()
		var mapData : FileData = DB.MapsDB.get(destinationID, null)
		if mapData:
			Launcher.GUI.choiceContext.Push(ContextData.new("gp_interact", mapData._name, ConfirmWarp.bind()))
			Launcher.GUI.choiceContext.FadeIn()
			contextDisplayed = true

func HideLabel():
	if not Launcher.GUI.IsDialogueContextOpened():
		Launcher.GUI.choiceContext.FadeOut()
		contextDisplayed = false

#
func _ready():
	collision_mask = 2

	self.body_entered.connect(bodyEntered)
	self.body_exited.connect(bodyExited)

	var particle : GPUParticles2D = WarpFx.instantiate()

	if not randomPoints.is_empty():
		var image := Image.create(randomPoints.size(), 1, false, Image.FORMAT_RGBF)
		for i in range(randomPoints.size()):
			var point : Vector2 = randomPoints[i]
			image.set_pixel(i, 0, Color(point.x, point.y, 0.0))
		var mat : ParticleProcessMaterial = particle.process_material as ParticleProcessMaterial
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
		mat.emission_shape_scale = Vector3(1.0, 1.0, 1.0)
		mat.emission_point_count = randomPoints.size()
		mat.emission_point_texture = ImageTexture.create_from_image(image)

	var areaRatio : float = areaSize / (32*32)
	particle.amount = int(float(defaultParticlesCount) * areaRatio)
	add_child.call_deferred(particle)
