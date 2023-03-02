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

var interactive : EntityInteractive		= EntityInteractive.new()
var inventory : EntityInventory			= EntityInventory.new()
var stat : EntityStats					= EntityStats.new()

# Animation
func GetNextState(checkSit : bool = false):
	var newEntityState			= entityState
	var currentVelocity			= velocity
	var velocityLengthSquared	= currentVelocity.length_squared()
	var isWalking				= velocityLengthSquared > 1
	var actionSitPressed		= Launcher.Action.IsActionPressed("gp_sit") if checkSit else false
	var actionSitJustPressed	= Launcher.Action.IsActionJustPressed("gp_sit") if checkSit else false

	match entityState:
		EntityEnums.State.IDLE:
			if isWalking:
				newEntityState = EntityEnums.State.WALK
			elif actionSitPressed:
				newEntityState = EntityEnums.State.SIT
		EntityEnums.State.WALK:
			if not isWalking:
				newEntityState = EntityEnums.State.IDLE
		EntityEnums.State.SIT:
			if not actionSitPressed and isWalking:
				newEntityState = EntityEnums.State.WALK
			elif actionSitJustPressed:
				newEntityState = EntityEnums.State.IDLE

	return newEntityState

func GetNextDirection():
	if velocity.length_squared() > 1:
		return velocity.normalized()
	else:
		return entityDirection

func ApplyNextState(nextState : EntityEnums.State, nextDirection : Vector2):
	if not animationTree or not animationState:
		pass

	animationTree.set("parameters/Idle/blend_position", nextDirection)
	animationTree.set("parameters/Sit/blend_position", nextDirection)
	animationTree.set("parameters/Walk/blend_position", nextDirection)

	match nextState:
		EntityEnums.State.IDLE:
			animationState.travel("Idle")
		EntityEnums.State.WALK:
			animationState.travel("Walk")
		EntityEnums.State.SIT:
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

	if _entityKind == "Player":
		EnableWarp()

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
func Update(nextVelocity : Vector2, gardbandPosition : Vector2):
	if Vector2(position - gardbandPosition).length() > 16:
		position = gardbandPosition
	velocity = nextVelocity

	UpdateState()
	if velocity != Vector2.ZERO:
		move_and_slide()

func EnableWarp():
	collision_layer	|= 1 << 1
	collision_mask	|= 1 << 1

#
func _ready():
	if animationTree:
		animationState = animationTree.get("parameters/playback")
