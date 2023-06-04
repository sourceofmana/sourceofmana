extends CharacterBody2D
class_name BaseEntity

#
var displayName : bool					= false
var entityName : String					= "PlayerName"

var entityState : EntityCommons.State	= EntityCommons.State.IDLE
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO

@onready var interactive : EntityInteractive	= $Interactions
var inventory : EntityInventory			= EntityInventory.new()
var stat : EntityStats					= EntityStats.new()
var visual : EntityVisual				= EntityVisual.new()

# Init
func SetKind(_entityKind : String, _entityID : String, _entityName : String):
	entityName	= _entityID if _entityName.length() == 0 else _entityName
	set_name(entityName)

func SetData(data : EntityData):
	# Stat
	stat.baseMoveSpeed	= data._walkSpeed
	stat.moveSpeed		= data._walkSpeed

	# Display
	displayName			= data._displayName
	SetVisual(data)

func SetVisual(data : EntityData):
	visual.Init(self, data)

#
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, nextState : EntityCommons.State):
	var dist = Vector2(gardbandPosition - position).length()
	if dist > Launcher.Conf.GetInt("Guardband", "MaxGuardbandDist", Launcher.Conf.Type.NETWORK):
		position = gardbandPosition

	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	entityState = nextState

#
func _physics_process(delta):
	velocity = entityVelocity

	var dist = entityPosOffset.length()
	if dist > Launcher.Conf.GetInt("Guardband", "StartGuardbandDist", Launcher.Conf.Type.NETWORK):
		var guardbandSpeed : int = Launcher.Conf.GetInt("Guardband", "PatchGuardband", Launcher.Conf.Type.NETWORK)
		var posOffsetFix : Vector2 = Vector2.ZERO.move_toward(entityPosOffset, delta) * guardbandSpeed
		entityPosOffset -= posOffsetFix
		velocity += posOffsetFix

	visual.Refresh(delta)

	if velocity != Vector2.ZERO:
		move_and_slide()

func _ready():
	if interactive:
		interactive.SpecificInit(self, self == Launcher.Player)
