extends Node2D
class_name EntityVisual

var entity : BaseEntity						= null
var sprites : Array[Sprite2D]				= []
var animation : AnimationPlayer				= null
var animationTree : AnimationTree			= null

var collision : CollisionShape2D			= null
var orientation : Vector2					= Vector2(0, 1)
var previousState : EntityCommons.State		= EntityCommons.State.UNKNOWN

var blendSpacePaths : Dictionary			= {}
var timeScalePaths : Dictionary				= {}

var spriteOffset : int						= 0

#
func SetMainMaterial(materialResource : Resource):
	Util.Assert(sprites[EntityCommons.Slot.BODY] != null, "Trying to assign a shader material to a non-existant texture")
	if sprites[EntityCommons.Slot.BODY]:
		sprites[EntityCommons.Slot.BODY].material = materialResource

func LoadSprite(slot : EntityCommons.Slot, sprite : Sprite2D, customTexturePath : String = ""):
	var materialResource : Resource = null
	if sprites[slot]:
		materialResource = sprites[slot].material
		sprites[slot].queue_free()
		sprites[slot] = null

	if not sprite:
		sprite = Sprite2D.new()
		animation.call_deferred("add_child", sprite)

	sprites[slot] = sprite
	sprites[slot].material = materialResource

	if customTexturePath.length() > 0:
		sprite.texture = FileSystem.LoadGfx(customTexturePath)

	spriteOffset = int(sprite.offset.y) - 10
	ApplySpriteOffset()

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
	sprites.resize(EntityCommons.Slot.COUNT)
	orientation = Vector2(0, 1)

func LoadData(data : EntityData):
	ResetData()

	# Collision
	if data._collision:
		collision = FileSystem.LoadEntityComponent("collisions/" + data._collision)
		if collision:
			entity.call_deferred("add_child", collision)

	# Animation
	if data._ethnicity:
		var preset : Node2D = FileSystem.LoadEntitySprite(data._ethnicity)
		entity.add_child(preset)
		animation = preset.get_node("Animation")
		if animation:
			# Animation Tree
			Util.Assert(animation.has_node("AnimationTree"), "No animation tree available for " + entity.entityName)
			if animation.has_node("AnimationTree"):
				animationTree = animation.get_node("AnimationTree")
				if animationTree:
					animationTree.set_active(true)

		# Body Sprite
		Util.Assert(preset.has_node("Sprite"), "No sprite available for " + entity.entityName)
		if preset.has_node("Sprite"):
			var sprite : Sprite2D = preset.get_node("Sprite")
			if sprite:
				LoadSprite(EntityCommons.Slot.BODY, sprite, data._customTexture)

	ResetAnimationValue()

func LoadAnimationPaths():
	for i in EntityCommons.State.COUNT:
		var stateName : String		= EntityCommons.GetStateName(i)
		var blendSpace : String		= "parameters/%s/BlendSpace2D/blend_position" % [stateName]
		var timeScale : String		= "parameters/%s/TimeScale/scale" % [stateName]

		if blendSpace in animationTree:
			blendSpacePaths[i] = blendSpace
		# Only set dynamic time scale for attack and walk as other can stay static
		if i == EntityCommons.State.ATTACK or i == EntityCommons.State.WALK:
			if timeScale in animationTree:
				timeScalePaths[i] = timeScale

func UpdateScale():
	if not entity or not animationTree:
		return

	if EntityCommons.State.WALK in timeScalePaths:
		animationTree[timeScalePaths[EntityCommons.State.WALK]] = entity.stat.walkRatio
	if EntityCommons.State.ATTACK in timeScalePaths:
		animationTree[timeScalePaths[EntityCommons.State.ATTACK]] = entity.stat.attackRatio

func ApplySpriteOffset():
	if entity.interactive and entity.interactive.visibleNode:
		entity.interactive.visibleNode.position.y = min(-32, spriteOffset)

func ResetAnimationValue():
	LoadAnimationPaths()
	UpdateScale()

	if entity and animationTree:
		var stateName = EntityCommons.GetStateName(previousState)
		animationTree[EntityCommons.playbackParameter].travel(stateName)
		if previousState in blendSpacePaths:
			var blendSpacePath = blendSpacePaths[previousState]
			animationTree[blendSpacePath] = orientation

#
func Init(parentEntity : BaseEntity, data : EntityData):
	if entity:
		entity.stat.ratio_updated.disconnect(self.UpdateScale)

	entity = parentEntity

	if entity and entity.stat:
		entity.stat.ratio_updated.connect(self.UpdateScale)

	LoadData(data)

func Ready():
	ApplySpriteOffset()

func Refresh(_delta: float):
	var currentEntityState = entity.entityState
	var entityVelocity = entity.entityVelocity
	# Check for changes in entity state and orientation
	var hasNewOrientation : bool = false

	if entityVelocity.length_squared() > 1:
		var newOrientation: Vector2 = entityVelocity.normalized()
		hasNewOrientation = orientation != newOrientation
		orientation = newOrientation

	if previousState == currentEntityState and not hasNewOrientation:
		return

	if currentEntityState in blendSpacePaths:
		var blendSpacePath = blendSpacePaths[currentEntityState]
		animationTree[blendSpacePath] = orientation

	if currentEntityState != previousState:
		var stateName = EntityCommons.GetStateName(currentEntityState)
		animationTree[EntityCommons.playbackParameter].travel(stateName)
		previousState = currentEntityState
