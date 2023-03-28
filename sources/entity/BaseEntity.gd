extends CharacterBody2D
class_name BaseEntity

#
@onready var interactive : EntityInteractive	= $Interactions

var sprite : Sprite2D					= null
var animation : Node					= null
var animationTree : AnimationTree		= null
var animationState : Resource			= null
var collision : CollisionShape2D		= null

var displayName : bool					= false
var entityName : String					= "PlayerName"
var entityState : EntityCommons.State	= EntityCommons.State.IDLE
var entityDirection : Vector2			= Vector2(0, 1)
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO

var inventory : EntityInventory			= EntityInventory.new()
var stat : EntityStats					= EntityStats.new()

# Animation
func UpdateDirection():
	if entityVelocity.length_squared() > 1:
		entityDirection = entityVelocity.normalized()

func UpdateAnimation():
	if animationTree and animationState:
		match entityState:
			EntityCommons.State.IDLE:
				animationTree.set("parameters/Idle/blend_position", entityDirection)
				animationState.travel("Idle")
			EntityCommons.State.WALK:
				animationTree.set("parameters/Walk/blend_position", entityDirection)
				animationState.travel("Walk")
			EntityCommons.State.SIT:
				animationTree.set("parameters/Sit/blend_position", entityDirection)
				animationState.travel("Sit")
			EntityCommons.State.ATTACK:
				animationTree.set("parameters/Attack/blend_position", entityDirection)
				animationState.travel("Attack")
			EntityCommons.State.DEATH:
				animationTree.set("parameters/Death/blend_position", entityDirection)
				animationState.travel("Death")

# Init
func SetKind(_entityKind : String, _entityID : String, _entityName : String):
	entityName	= _entityName
	if entityName.length() == 0:
		set_name(_entityID)
	else:
		set_name(entityName)

func SetData(data : Object):
	# Display
	entityName		= data._name
	displayName		= data._displayName

	# Sprite
	sprite = Launcher.FileSystem.LoadPreset("sprites/" + data._ethnicity + data._gender)
	if sprite:
		if data._customTexture:
			sprite.texture = Launcher.FileSystem.LoadGfx(data._customTexture)
		add_child(sprite)

	# Animation
	if data._animation:
		animation = Launcher.FileSystem.LoadPreset("animations/" + data._animation)
		var canFetchAnimTree = animation != null && animation.has_node("AnimationTree")
		Util.Assert(canFetchAnimTree, "No AnimationTree found")
		if canFetchAnimTree:
			animationTree = animation.get_node("AnimationTree")
		add_child(animation)

	# Collision
	collision = Launcher.FileSystem.LoadPreset("collisions/" + data._collision)
	if collision:
		add_child(collision)

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

	UpdateDirection()
	UpdateAnimation()

	if velocity != Vector2.ZERO:
		move_and_slide()

func _ready():
	if animationTree:
		animationState = animationTree.get("parameters/playback")
	if interactive:
		interactive.SpecificInit(self, self == Launcher.Player)
