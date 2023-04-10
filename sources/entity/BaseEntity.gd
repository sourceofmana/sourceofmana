extends CharacterBody2D
class_name BaseEntity

#
@onready var interactive : EntityInteractive	= $Interactions

var sprite : Sprite2D					= null
var animation : Node					= null
var animationTree : AnimationTree		= null
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
	if animation and animationTree:
		var animationState : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
		var stateName : String = EntityCommons.GetStateName(entityState)
		if animationState:
			animationTree.set("parameters/%s/BlendSpace2D/blend_position" % stateName, entityDirection)
			animationState.travel(stateName)
			animationTree.set("parameters/%s/TimeScale/scale" % stateName, GetAnimationScale())

func GetAnimationScale() -> float:
	var ratio : float = 1.0
	match entityState:
		EntityCommons.State.ATTACK:
			if stat.attackSpeed > 0:
				ratio = stat.baseAttackSpeed / stat.attackSpeed
		EntityCommons.State.WALK:
			if stat.moveSpeed > 0:
				ratio = stat.baseMoveSpeed / stat.moveSpeed
	return ratio

# Init
func SetKind(_entityKind : String, _entityID : String, _entityName : String):
	entityName	= _entityName
	if entityName.length() == 0:
		set_name(_entityID)
	else:
		set_name(entityName)

func SetData(data : Object):
	# Stat
	stat.baseMoveSpeed = data._walkSpeed
	stat.moveSpeed	= data._walkSpeed

	# Display
	entityName		= data._name
	displayName		= data._displayName

	# Sprite
	sprite = Launcher.FileSystem.LoadEntitySprite(data._ethnicity)
	if sprite:
		if data._customTexture:
			sprite.texture = Launcher.FileSystem.LoadGfx(data._customTexture)
		add_child(sprite)

		Util.Assert(sprite.get_child_count() > 0, "No animation available for " + entityName)
		if sprite.get_child_count() > 0:
			animation = sprite.get_child(0)

			Util.Assert(animation.get_child_count() > 0, "No animation tree available for " + entityName)
			if animation.get_child_count() > 0:
				animationTree = animation.get_child(0)

	# Collision
	collision = Launcher.FileSystem.LoadEntityComponent("collisions/" + data._collision)
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
	if interactive:
		interactive.SpecificInit(self, self == Launcher.Player)
