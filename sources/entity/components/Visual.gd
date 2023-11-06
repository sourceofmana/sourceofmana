extends Node2D
class_name EntityVisual

var entity : BaseEntity						= null
var sprites : Array[Sprite2D]				= []
var animationPlayer : AnimationPlayer		= null
var animationTree : AnimationTree			= null

var collision : CollisionShape2D			= null
var orientation : Vector2					= Vector2(0, 1)
var previousState : EntityCommons.State		= EntityCommons.State.UNKNOWN

#
func GetAnimationScale() -> float:
	if entity.entityState ==  3:
		return entity.stat.attackRatio
	elif entity.entityState == 1:
		return entity.stat.walkRatio
	return 1.0

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

#
func Init(parentEntity : BaseEntity, data : EntityData):
	entity = parentEntity
	LoadData(data)

func Refresh(_delta : float):
	var hasNewOrientation = false
	if entity.entityVelocity.length_squared() > 1:
		var newOrientation : Vector2 = entity.entityVelocity.normalized()
		hasNewOrientation = orientation != newOrientation
		orientation = newOrientation

	var hasNewState = previousState != entity.entityState

	if not hasNewState and not hasNewOrientation:
		return

	var stateName : String = EntityCommons.GetStateName(entity.entityState)
	animationTree["parameters/%s/BlendSpace2D/blend_position" % stateName] = orientation

	if hasNewState:
		animationTree["parameters/playback"].travel(stateName)
		animationTree["parameters/%s/TimeScale/scale" % stateName] = GetAnimationScale()
