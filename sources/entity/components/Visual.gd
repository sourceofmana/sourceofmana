extends Node2D
class_name EntityVisual

var entity : BaseEntity						= null
var sprites : Array[Sprite2D]				= []
var animation : Node						= null
var animationTree : AnimationTree			= null
var collision : CollisionShape2D			= null
var orientation : Vector2					= Vector2(0, 1)

#
func GetAnimationScale() -> float:
	var ratio : float = 1.0
	var stat = entity.stat
	match entity.entityState:
		EntityCommons.State.ATTACK:
			if stat.attackSpeed > 0:
				ratio = stat.baseAttackSpeed / stat.attackSpeed
		EntityCommons.State.WALK:
			if stat.moveSpeed > 0:
				ratio = stat.baseMoveSpeed / stat.moveSpeed
	return ratio

func AddSprite(slot : EntityCommons.Slot, spritePath : String) -> Sprite2D:
	var sprite : Sprite2D = null
	if slot < EntityCommons.Slot.COUNT:
		if sprites[slot]:
			sprites[slot].queue_free()
			sprites[slot] = null

		sprite = Launcher.FileSystem.LoadEntitySprite(spritePath)
		sprites[slot] = sprite

	return sprite

#
func Init(parentEntity : BaseEntity, data : EntityData):
	entity = parentEntity

	# Sprite
	sprites.resize(EntityCommons.Slot.COUNT)
	var sprite : Sprite2D = AddSprite(EntityCommons.Slot.BODY, data._ethnicity)
	if sprite:
		if data._customTexture:
			sprite.texture = Launcher.FileSystem.LoadGfx(data._customTexture)
		entity.call_deferred("add_child", sprite)

		Util.Assert(sprite.get_child_count() > 0, "No animation available for " + entity.entityName)
		if sprite.get_child_count() > 0:
			animation = sprite.get_child(0)

			Util.Assert(animation.get_child_count() > 0, "No animation tree available for " + entity.entityName)
			if animation.get_child_count() > 0:
				animationTree = animation.get_child(0)
				animationTree.set_active(true)

	# Collision
	collision = Launcher.FileSystem.LoadEntityComponent("collisions/" + data._collision)
	if collision:
		entity.add_child(collision)

func Refresh(_delta : float):
	if entity.entityVelocity.length_squared() > 1:
		orientation = entity.entityVelocity.normalized()

	if animation and animationTree:
		var animationState : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
		var stateName : String = EntityCommons.GetStateName(entity.entityState)
		if animationState:
			animationTree.set("parameters/%s/BlendSpace2D/blend_position" % stateName, orientation)
			animationState.travel(stateName)
			animationTree.set("parameters/%s/TimeScale/scale" % stateName, GetAnimationScale())
