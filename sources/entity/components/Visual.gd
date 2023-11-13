extends Node2D
class_name EntityVisual

var entity : BaseEntity						= null
var sprites : Array[Sprite2D]				= []
var animationPlayer : AnimationPlayer		= null
var animationTree : AnimationTree			= null

var collision : CollisionShape2D			= null
var orientation : Vector2					= Vector2(0, 1)
var previousState : EntityCommons.State		= EntityCommons.State.UNKNOWN

var blendSpacePaths : Dictionary			= {}
var timeScalePaths : Dictionary				= {}

#
func LoadSprite(slot : EntityCommons.Slot, spritePath : String) -> Sprite2D:
	var sprite : Sprite2D = null
	if slot < EntityCommons.Slot.COUNT:
		if sprites[slot]:
			sprites[slot].queue_free()
			sprites[slot] = null

		sprite = FileSystem.LoadEntitySprite(spritePath)
		sprites[slot] = sprite

	return sprite

func ResetData():
	if collision:
		collision.queue_free()
		collision = null
	if animationTree:
		animationTree = null
	if animationPlayer:
		animationPlayer = null
	for spriteID in sprites.size():
		if sprites[spriteID]:
			sprites[spriteID].queue_free()
			sprites[spriteID] = null
	orientation = Vector2(0, 1)

func LoadData(data : EntityData):
	ResetData()

	# Sprite
	sprites.resize(EntityCommons.Slot.COUNT)
	var sprite : Sprite2D = LoadSprite(EntityCommons.Slot.BODY, data._ethnicity)
	if sprite:
		if data._customTexture:
			sprite.texture = FileSystem.LoadGfx(data._customTexture)
		entity.call_deferred("add_child", sprite)

		if sprite.vframes > 0:
			if entity.interactive and entity.interactive.visibleNode:
				var frameVerticalOffset : int = (int)(sprite.texture.get_size().y / sprite.vframes)
				entity.interactive.visibleNode.position.y = -frameVerticalOffset if frameVerticalOffset > 32 else -32

		Util.Assert(sprite.get_child_count() > 0, "No animation available for " + entity.entityName)
		if sprite.get_child_count() > 0:
			animationPlayer = sprite.get_child(0)

			Util.Assert(animationPlayer.get_child_count() > 0, "No animation tree available for " + entity.entityName)
			if animationPlayer.get_child_count() > 0:
				animationTree = animationPlayer.get_child(0)
				animationTree.set_active(true)

	# Collision
	if data._collision:
		collision = FileSystem.LoadEntityComponent("collisions/" + data._collision)
		if collision:
			entity.call_deferred("add_child", collision)

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

func ResetAnimationValue():
	LoadAnimationPaths()
	UpdateScale()

	if entity and animationTree:
		var stateName = EntityCommons.GetStateName(previousState)
		animationTree[EntityCommons.playbackParameter].travel(stateName)
		if previousState in blendSpacePaths:
			var blendSpacePath = blendSpacePaths[previousState]
			animationTree[blendSpacePath] = orientation

func SetMaterial(matPath : String):
	if sprites[EntityCommons.Slot.BODY]:
		sprites[EntityCommons.Slot.BODY].material = FileSystem.FileLoad(matPath)

#
func Init(parentEntity : BaseEntity, data : EntityData):
	if entity:
		entity.stat.ratio_updated.disconnect(self.UpdateScale)

	entity = parentEntity

	if entity and entity.stat:
		entity.stat.ratio_updated.connect(self.UpdateScale)

	LoadData(data)
	ResetAnimationValue()

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
