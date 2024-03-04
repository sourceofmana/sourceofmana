extends Node2D
class_name EntityVisual

#
signal spriteOffsetUpdate

#
var entity : BaseEntity						= null
var sprites : Array[Sprite2D]				= []
var animation : AnimationPlayer				= null
var animationTree : AnimationTree			= null

var collision : CollisionShape2D			= null
var previousOrientation : Vector2			= Vector2.ZERO
var previousState : ActorCommons.State		= ActorCommons.State.UNKNOWN

var blendSpacePaths : Dictionary			= {}
var timeScalePaths : Dictionary				= {}

var skillCastName : String					= ""
var attackAnimLength : float				= 1.0

#
func SetMainMaterial(materialResource : Resource):
	Util.Assert(sprites[ActorCommons.Slot.BODY] != null, "Trying to assign a shader material to a non-existant texture")
	if sprites[ActorCommons.Slot.BODY]:
		sprites[ActorCommons.Slot.BODY].material = materialResource

func LoadSprite(slot : ActorCommons.Slot, sprite : Sprite2D, customTexturePath : String = ""):
	var materialResource : Resource = null
	if sprites[slot]:
		materialResource = sprites[slot].material
		sprites[slot].queue_free()
		sprites[slot] = null

	if not sprite:
		sprite = Sprite2D.new()
		animation.add_child.call_deferred(sprite)

	sprites[slot] = sprite
	sprites[slot].material = materialResource

	if customTexturePath.length() > 0:
		sprite.texture = FileSystem.LoadGfx(customTexturePath)

func ResetData():
	if collision:
		collision.queue_free()
		collision = null
	if animationTree:
		animationTree = null
	if animation:
		animation.queue_free()
		animation = null
	for spriteID in sprites.size():
		if sprites[spriteID]:
			sprites[spriteID].queue_free()
			sprites[spriteID] = null
	sprites.resize(ActorCommons.Slot.COUNT)

func LoadData(data : EntityData):
	ResetData()

	# Collision
	if data._collision:
		collision = FileSystem.LoadEntityComponent("collisions/" + data._collision)
		if collision:
			entity.add_child.call_deferred(collision)

	# Animation
	if data._ethnicity:
		var preset : Node2D = FileSystem.LoadEntitySprite(data._ethnicity)
		entity.add_child(preset)
		animation = preset.get_node("Animation")
		if animation:
			# Animation Tree
			Util.Assert(animation.has_node("AnimationTree"), "No animation tree available for " + entity.get_name())
			if animation.has_node("AnimationTree"):
				animationTree = animation.get_node("AnimationTree")
				if animationTree:
					animationTree.set_active(true)

		# Body Sprite
		Util.Assert(preset.has_node("Sprite"), "No sprite available for " + entity.get_name())
		if preset.has_node("Sprite"):
			var sprite : Sprite2D = preset.get_node("Sprite")
			if sprite:
				LoadSprite(ActorCommons.Slot.BODY, sprite, data._customTexture)

	ResetAnimationValue()

func LoadAnimationPaths():
	for i in ActorCommons.State.COUNT:
		var stateName : String		= ActorCommons.GetStateName(i)
		var blendSpace : String		= "parameters/%s/BlendSpace2D/blend_position" % [stateName]
		var timeScale : String		= "parameters/%s/TimeScale/scale" % [stateName]
		if animation.has_animation("AttackDown"):
			var attackAnim : Animation	= animation.get_animation("AttackDown")
			attackAnimLength = attackAnim.length if attackAnim else 1.0

		if blendSpace in animationTree:
			blendSpacePaths[i] = blendSpace

		# Only set dynamic time scale for attack and walk as other can stay static
		if i == ActorCommons.State.ATTACK or i == ActorCommons.State.WALK:
			if timeScale in animationTree:
				timeScalePaths[i] = timeScale

func UpdateScale():
	if not entity or not animationTree:
		return

	if ActorCommons.State.WALK in timeScalePaths:
		animationTree[timeScalePaths[ActorCommons.State.WALK]] = Formula.GetWalkRatio(entity.stat)
	if ActorCommons.State.ATTACK in timeScalePaths and attackAnimLength > 0:
		var test = attackAnimLength / entity.stat.current.castAttackDelay
		animationTree[timeScalePaths[ActorCommons.State.ATTACK]] = test

func ResetAnimationValue():
	if not entity or not animationTree:
		return

	LoadAnimationPaths()
	UpdateScale()
	RefreshTree()

func SyncPlayerOffset():
	var spriteOffset : int = 0
	if sprites[ActorCommons.Slot.BODY]:
		spriteOffset = int(sprites[ActorCommons.Slot.BODY].offset.y)

	spriteOffsetUpdate.emit(spriteOffset)

#
func Init(parentEntity : BaseEntity, data : EntityData):
	entity = parentEntity

	if entity and entity.stat:
		Callback.PlugCallback(entity.stat.entity_stats_updated, self.UpdateScale)

	LoadData(data)
	SyncPlayerOffset()

func Refresh(_delta: float):
	if not animationTree or not entity:
		return

	var currentVelocity = entity.velocity
	var newOrientation : Vector2 = currentVelocity.normalized() if currentVelocity.length_squared() > 1 else entity.entityOrientation
	var newState : ActorCommons.State = ActorCommons.State.WALK if currentVelocity.length_squared() > 1 else entity.state

	if previousState != newState or previousOrientation != newOrientation:
		previousState = newState
		previousOrientation = newOrientation
		RefreshTree()

func RefreshTree():
	if previousState in blendSpacePaths:
		var blendSpacePath = blendSpacePaths[previousState]
		animationTree[blendSpacePath] = previousOrientation

	var stateName = ActorCommons.GetStateName(previousState)
	animationTree[ActorCommons.playbackParameter].travel(stateName)
