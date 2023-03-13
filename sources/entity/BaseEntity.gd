extends CharacterBody2D
class_name BaseEntity

#
var sprite : Sprite2D					= null
var animation : Node					= null
var animationTree : AnimationTree		= null
var animationState : Resource			= null
var collision : CollisionShape2D		= null

var displayName : bool					= false
var entityName : String					= "PlayerName"
var entityState : EntityEnums.State		= EntityEnums.State.IDLE
var entityDirection : Vector2			= Vector2(0, 1)
var entityVelocity : Vector2			= Vector2.ZERO
var entityPosOffset : Vector2			= Vector2.ZERO
var entitySitting : bool				= false

var interactive : EntityInteractive		= EntityInteractive.new()
var inventory : EntityInventory			= EntityInventory.new()
var stat : EntityStats					= EntityStats.new()

# Animation
func GetNextState():
	var newEntityState			= entityState
	var velocityLengthSquared	= entityVelocity.length_squared()
	var isWalking				= velocityLengthSquared > 1

	match entityState:
		EntityEnums.State.IDLE:
			if isWalking:
				newEntityState = EntityEnums.State.WALK
			elif entitySitting:
				newEntityState = EntityEnums.State.SIT
		EntityEnums.State.WALK:
			if not isWalking:
				newEntityState = EntityEnums.State.IDLE
		EntityEnums.State.SIT:
			if not entitySitting:
				if isWalking:
					newEntityState = EntityEnums.State.WALK
				else:
					newEntityState = EntityEnums.State.IDLE

	return newEntityState

func GetNextDirection():
	if entityVelocity.length_squared() > 1:
		return entityVelocity.normalized()
	else:
		return entityDirection

func ApplyNextState(nextState : EntityEnums.State, nextDirection : Vector2):
	if animationTree and animationState:
		match nextState:
			EntityEnums.State.IDLE:
				animationTree.set("parameters/Idle/blend_position", nextDirection)
				animationState.travel("Idle")
			EntityEnums.State.WALK:
				animationTree.set("parameters/Walk/blend_position", nextDirection)
				animationState.travel("Walk")
			EntityEnums.State.SIT:
				animationTree.set("parameters/Sit/blend_position", nextDirection)
				animationState.travel("Sit")

	entityState		= nextState
	entityDirection	= nextDirection

func UpdateState():
	var nextState : EntityEnums.State = GetNextState()
	var nextDirection : Vector2		= GetNextDirection()
	var hasNewState : bool			= nextState != entityState
	var hasNewDirection : bool		= nextDirection != entityDirection

	if hasNewState or hasNewDirection:
		ApplyNextState(nextState, nextDirection)

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
	if !data._ethnicity.is_empty() or !data._gender.is_empty():
		sprite = Launcher.FileSystem.LoadPreset("sprites/" + data._ethnicity + data._gender)
		if sprite != null && !data._customTexture.is_empty():
			sprite.texture = Launcher.FileSystem.LoadGfx(data._customTexture)
		add_child(sprite)

	# Animation
	if data._animation:
		animation = Launcher.FileSystem.LoadPreset("animations/" + data._animation)
		var canFetchAnimTree = animation != null && animation.has_node("AnimationTree")
		Launcher.Util.Assert(canFetchAnimTree, "No AnimationTree found")
		if canFetchAnimTree:
			animationTree = animation.get_node("AnimationTree")
		add_child(animation)

	# Collision
	if data._collision:
		collision = Launcher.FileSystem.LoadPreset("collisions/" + data._collision)
		add_child(collision)

#
func Update(nextVelocity : Vector2, gardbandPosition : Vector2, isSitting : bool):
	var dist = Vector2(gardbandPosition - position).length()
	if dist > Launcher.Conf.GetInt("Guardband", "MaxGuardbandDist", Launcher.Conf.Type.NETWORK):
		position = gardbandPosition

	entityPosOffset = gardbandPosition - position
	entityVelocity = nextVelocity
	entitySitting = isSitting

#
func _physics_process(delta):
	velocity = entityVelocity

	var dist = entityPosOffset.length()
	if dist > Launcher.Conf.GetInt("Guardband", "StartGuardbandDist", Launcher.Conf.Type.NETWORK):
		var guardbandSpeed : int = Launcher.Conf.GetInt("Guardband", "PatchGuardband", Launcher.Conf.Type.NETWORK)
		var posOffsetFix : Vector2 = Vector2.ZERO.move_toward(entityPosOffset, delta) * guardbandSpeed
		entityPosOffset -= posOffsetFix
		velocity += posOffsetFix

	UpdateState()

	if velocity != Vector2.ZERO:
		move_and_slide()

func _ready():
	if animationTree:
		animationState = animationTree.get("parameters/playback")

func _init():
	pass
