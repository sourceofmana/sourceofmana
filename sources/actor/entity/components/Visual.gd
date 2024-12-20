extends Node2D
class_name EntityVisual

#
signal spriteOffsetUpdate

#
var collision : CollisionShape2D			= null
var animation : AnimationPlayer				= null
var animationTree : AnimationTree			= null
var sprites : Array[Sprite2D]				= []

var previousOrientation : Vector2			= Vector2.ZERO
var previousState : ActorCommons.State		= ActorCommons.State.UNKNOWN

var blendSpacePaths : Dictionary			= {}
var timeScalePaths : Dictionary				= {}

var skillCastID : int						= DB.UnknownHash
var attackAnimLength : float				= 1.0

#
func LoadSpriteSlot(slot : ActorCommons.Slot, sprite : Sprite2D):
	if sprites[slot]:
		sprites[slot].queue_free()
		sprites[slot] = null

	if sprite:
		sprites[slot] = sprite

func ResetData():
	for child in get_children():
		child.queue_free()
	for spriteID in sprites.size():
		sprites[spriteID] = null
	if collision:
		collision.queue_free()
		collision = null

func LoadData(data : EntityData):
	ResetData()

	# Collision
	if data._collision and get_parent().type == ActorCommons.Type.PLAYER:
		collision = FileSystem.LoadEntityComponent("collisions/" + data._collision)
		if collision:
			get_parent().add_child.call_deferred(collision)

	# Sprite Preset
	if data._ethnicity:
		var preset : Node2D = FileSystem.LoadEntitySprite(data._ethnicity)
		if preset:
			add_child.call_deferred(preset)

		# Animation
		if preset and preset.has_node("Animation"):
			animation = preset.get_node("Animation")

		# Animation Tree
		if animation and animation.has_node("AnimationTree"):
			animationTree = animation.get_node("AnimationTree")
			if animationTree:
				animationTree.set_active(true)

		# Sprites
		if preset:
			for slot in ActorCommons.Slot.COUNT:
				var slotName : String = ActorCommons.GetSlotName(slot)
				var sprite : Sprite2D = null
				if preset.has_node(slotName):
					sprite = preset.get_node(slotName)
				elif data._customTextures[slot]:
					sprite = Sprite2D.new()
					sprite.set_name(slotName)
					preset.add_child.call_deferred(sprite)

				if sprite:
					if data._customTextures[slot]:
						sprite.texture = FileSystem.LoadGfx(data._customTextures[slot])
					if data._customShaders[slot]:
						sprite.material = FileSystem.LoadResource(data._customShaders[slot], false)
					LoadSpriteSlot(slot, sprite)

	ResetAnimationValue()

func LoadAnimationPaths():
	for i in ActorCommons.State.COUNT:
		var stateName : String		= ActorCommons.GetStateName(i)
		var blendSpace : String		= "parameters/%s/BlendSpace2D/blend_position" % [stateName]
		if animation.has_animation("AttackDown"):
			var attackAnim : Animation	= animation.get_animation("AttackDown")
			attackAnimLength = attackAnim.length if attackAnim else 1.0

		if blendSpace in animationTree:
			blendSpacePaths[i] = blendSpace

		# Only set dynamic time scale for attack and walk as other can stay static
		if i == ActorCommons.State.ATTACK or i == ActorCommons.State.WALK:
			var timeScale : String = "parameters/%s/TimeScale/scale" % [stateName]
			if timeScale in animationTree:
				timeScalePaths[i] = timeScale

func UpdateScale():
	if not animationTree:
		return

	if ActorCommons.State.WALK in timeScalePaths:
		animationTree[timeScalePaths[ActorCommons.State.WALK]] = Formula.GetWalkRatio(get_parent().stat)
	if ActorCommons.State.ATTACK in timeScalePaths and get_parent().stat.current.castAttackDelay > 0:
		animationTree[timeScalePaths[ActorCommons.State.ATTACK]] = attackAnimLength / get_parent().stat.current.castAttackDelay

func ResetAnimationValue():
	if not animationTree:
		return

	LoadAnimationPaths()
	UpdateScale()
	RefreshTree()

func GetPlayerOffset() -> int:
	var spriteOffset : int = ActorCommons.interactionDisplayOffset
	if sprites[ActorCommons.Slot.BODY]:
		spriteOffset = int(sprites[ActorCommons.Slot.BODY].offset.y)
	return spriteOffset
#
func Init(data : EntityData):
	Callback.PlugCallback(get_parent().stat.entity_stats_updated, self.UpdateScale)
	sprites.resize(ActorCommons.Slot.COUNT)

	LoadData(data)

func _process(_delta):
	if not animationTree:
		return

	var currentVelocity : Vector2 = get_parent().velocity
	var isMoving : bool = currentVelocity.length_squared() > 1
	var newOrientation : Vector2 = currentVelocity.normalized() if isMoving else get_parent().entityOrientation
	var newState : ActorCommons.State = ActorCommons.State.WALK if isMoving else get_parent().state

	if previousState != newState or previousOrientation != newOrientation:
		previousState = newState
		previousOrientation = newOrientation
		RefreshTree()

func RefreshTree():
	if previousState in blendSpacePaths:
		var blendSpacePath : String = blendSpacePaths[previousState]
		animationTree[blendSpacePath] = previousOrientation

	var stateName : String = ActorCommons.GetStateName(previousState)
	animationTree[ActorCommons.playbackParameter].travel(stateName)
