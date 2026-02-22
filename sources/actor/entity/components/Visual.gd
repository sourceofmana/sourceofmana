extends Node2D
class_name EntityVisual

#
signal spriteOffsetUpdate

#
@onready var entity : Entity				= get_parent()

var preset : Node2D							= null
var collision : CollisionShape2D			= null
var animation : AnimationPlayer				= null
var animationTree : AnimationTree			= null
var sprites : Array[Sprite2D]				= []

var previousOrientation : Vector2			= Vector2.ZERO
var previousState : ActorCommons.State		= ActorCommons.State.UNKNOWN

var blendSpacePaths : Dictionary[int, String]	= {}
var timeScalePaths : Dictionary[int, String]	= {}
var stateNamePaths : Dictionary[int, String]	= {}

var skillCastID : int						= DB.UnknownHash
var attackAnimLength : float				= 1.0

#
func LoadSpriteSlot(slot : ActorCommons.Slot, sprite : Sprite2D):
	if sprites[slot] != sprite:
		if sprites[slot]:
			sprites[slot].queue_free()
			sprites[slot] = null

		if sprite:
			sprites[slot] = sprite
			if slot == ActorCommons.Slot.BODY:
				spriteOffsetUpdate.emit()


func ResetData():
	for child in get_children():
		child.queue_free()
	for spriteID in sprites.size():
		sprites[spriteID] = null
	preset = null
	if collision:
		collision.queue_free()
		collision = null

func LoadData(data : EntityData):
	ResetData()

	# Collision
	if data._collision and entity.type == ActorCommons.Type.PLAYER:
		collision = FileSystem.LoadEntityComponent("collisions/" + data._collision)
		if collision:
			entity.add_child.call_deferred(collision)

	# Sprite Preset
	if data._spritePreset:
		preset = FileSystem.LoadEntitySprite(data._spritePreset)
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
				if slot == ActorCommons.Slot.BODY:
					SetBody()
				elif slot == ActorCommons.Slot.FACE:
					SetFace()
				elif slot == ActorCommons.Slot.HAIR:
					SetHair()
				elif slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT:
					SetEquipment(slot, data)

	ResetAnimationValue()

func SetSkinSlot(slot : ActorCommons.Slot, raceData : RaceData, textures : Array):
	var sprite : Sprite2D = preset.get_node_or_null(ActorCommons.GetSlotName(slot))
	if not sprite:
		return

	var slotTexture : Texture2D = sprite.get_texture()
	var slotMaterial : Material = null

	if not entity.stat.IsMorph():
		var hasOverrideTexture : bool = false
		var hasOverrideMaterial : bool = false

		if entity.data and slot == ActorCommons.Slot.BODY:
			if entity.data._customTexture:
				slotTexture = FileSystem.LoadGfx(entity.data._customTexture)
				hasOverrideTexture = true
			if entity.data._customMaterial:
				slotMaterial = FileSystem.LoadPalette(entity.data._customMaterial._path)
				hasOverrideMaterial = true

		if not hasOverrideTexture:
			slotTexture = FileSystem.LoadGfx(textures[entity.stat.gender])
		if not hasOverrideMaterial:
			if entity.stat.skintone in raceData._skins:
				var skinData : FileData = raceData._skins[entity.stat.skintone]
				if skinData and not skinData._path.is_empty():
					slotMaterial = FileSystem.LoadPalette(skinData._path)

	sprite.set_texture(slotTexture)
	sprite.set_material(slotMaterial)
	LoadSpriteSlot(slot, sprite)

func SetBody():
	if entity.stat.race == DB.UnknownHash:
		SetData(ActorCommons.Slot.BODY, entity.data)
	else:
		var raceData : RaceData = DB.GetRace(entity.stat.race)
		if raceData:
			SetSkinSlot(ActorCommons.Slot.BODY, raceData, raceData._bodies)

func SetFace():
	if entity.stat.race == DB.UnknownHash:
		return
	var raceData : RaceData = DB.GetRace(entity.stat.race)
	if raceData:
		SetSkinSlot(ActorCommons.Slot.FACE, raceData, raceData._faces)

func SetHair():
	var slotName : String = ActorCommons.GetSlotName(ActorCommons.Slot.HAIR)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	var slotTexture : Texture2D = null
	var slotMaterial : Material = null

	if not entity.stat.IsMorph():
		var hairstyleData : FileData = DB.GetHairstyle(entity.stat.hairstyle) if entity.stat.hairstyle != DB.UnknownHash else null
		var haircolorData : FileData = DB.GetPalette(DB.Palette.HAIR, entity.stat.haircolor) if entity.stat.haircolor != DB.UnknownHash else null
		if hairstyleData != null and haircolorData != null:
			slotTexture = FileSystem.LoadGfx(hairstyleData._path)
			slotMaterial = FileSystem.LoadPalette(haircolorData._path)

	sprite.set_texture(slotTexture)
	sprite.set_material(slotMaterial)

	LoadSpriteSlot(ActorCommons.Slot.HAIR, sprite)

func SetEquipment(slot : int, data : EntityData = null):
	var slotName : String = ActorCommons.GetSlotName(slot)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	var slotTexture : Texture2D = null
	var slotMaterial : Material = null

	if not entity.stat.IsMorph():
		var cell : ItemCell = entity.inventory.equipment[slot] if entity.inventory else (data._equipment[slot] if data else null)
		if cell != null:
			slotTexture = cell.textures[entity.stat.gender]
			slotMaterial = cell.shader

	sprite.set_texture(slotTexture)
	sprite.set_material(slotMaterial)
	LoadSpriteSlot(slot, sprite)

func SetData(slot : int, data : EntityData):
	var slotName : String = ActorCommons.GetSlotName(slot)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	if data and slot == ActorCommons.Slot.BODY:
		if data._customTexture:
			sprite.set_texture(FileSystem.LoadGfx(data._customTexture))
		if data._customMaterial:
			sprite.set_material(FileSystem.LoadPalette(data._customMaterial._path))

	LoadSpriteSlot(slot, sprite)

func LoadAnimationPaths():
	if animation.has_animation("AttackDown"):
		var attackAnim : Animation = animation.get_animation("AttackDown")
		attackAnimLength = attackAnim.length if attackAnim else 1.0

	for i in ActorCommons.State.COUNT:
		var stateName : String		= ActorCommons.GetStateName(i)
		var blendSpace : String		= "parameters/%s/BlendSpace2D/blend_position" % [stateName]

		stateNamePaths[i] = stateName

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
		animationTree[timeScalePaths[ActorCommons.State.WALK]] = Formula.GetWalkRatio(entity.stat)
	if ActorCommons.State.ATTACK in timeScalePaths and entity.stat.current.castAttackDelay > 0:
		animationTree[timeScalePaths[ActorCommons.State.ATTACK]] = attackAnimLength / entity.stat.current.castAttackDelay

func ResetAnimationValue():
	if not animationTree:
		return

	LoadAnimationPaths()
	UpdateScale()
	RefreshTree()

func GetPlayerOffset() -> int:
	var spriteOffset : int = ActorCommons.interactionDisplayOffset
	if sprites[ActorCommons.Slot.BODY]:
		spriteOffset = -1 * int(sprites[ActorCommons.Slot.BODY].offset.y)
	return spriteOffset

#
func Init(data : EntityData):
	Callback.PlugCallback(entity.stat.entity_stats_updated, self.UpdateScale)
	LoadData(data)

func RefreshTree(resetOnTeleport : bool = true):
	if previousState in blendSpacePaths:
		animationTree[blendSpacePaths[previousState]] = previousOrientation

	if resetOnTeleport and previousState in stateNamePaths:
		animationTree[ActorCommons.playbackParameter].travel(stateNamePaths[previousState], true)

		# Random default offset for IDLE and UNKNOWN state of [0;1] second
		if previousState <= ActorCommons.State.IDLE:
			animationTree.advance(randf())

#
func _init():
	sprites.resize(ActorCommons.SlotEquipmentCount + ActorCommons.SlotModifierCount)

func _process(_delta):
	if not animationTree:
		return

	var currentVelocity : Vector2 = entity.entityVelocity
	var isMoving : bool = currentVelocity.length_squared() > 1
	var newOrientation : Vector2 = currentVelocity.normalized() if isMoving else entity.entityOrientation
	var newState : ActorCommons.State = ActorCommons.State.WALK if isMoving else entity.state
	var differentState : bool = previousState != newState
	if previousOrientation != newOrientation or differentState:
		previousState = newState
		previousOrientation = newOrientation
		RefreshTree(differentState)
