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

var blendSpacePaths : Dictionary			= {}
var timeScalePaths : Dictionary				= {}

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
	if data._collision and get_parent().type == ActorCommons.Type.PLAYER:
		collision = FileSystem.LoadEntityComponent("collisions/" + data._collision)
		if collision:
			get_parent().add_child.call_deferred(collision)

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

func SetBody():
	var slotName : String = ActorCommons.GetSlotName(ActorCommons.Slot.BODY)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	if entity.stat.race == DB.UnknownHash:
		SetData(ActorCommons.Slot.BODY, entity.data)
		return

	var raceData : RaceData = DB.GetRace(entity.stat.race)
	if raceData == null:
		return

	var slotTexture : Texture2D = sprite.get_texture()
	var slotMaterial : Material = null

	if not entity.stat.IsMorph():
		slotTexture = FileSystem.LoadGfx(raceData._bodies[entity.stat.gender])
		if entity.stat.skintone in raceData._skins:
			var skinData : TraitData = raceData._skins[entity.stat.skintone]
			if skinData and not skinData._path.is_empty():
				slotMaterial = FileSystem.LoadPalette(raceData._skins[entity.stat.skintone]._path)

	sprite.set_texture(slotTexture)
	sprite.set_material(slotMaterial)
	LoadSpriteSlot(ActorCommons.Slot.BODY, sprite)

func SetFace():
	var slotName : String = ActorCommons.GetSlotName(ActorCommons.Slot.FACE)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	if entity.stat.race == DB.UnknownHash:
		return

	var raceData : RaceData = DB.GetRace(entity.stat.race)
	if raceData == null:
		return

	var slotTexture : Texture2D = sprite.get_texture()
	var slotMaterial : Material = null

	if not entity.stat.IsMorph():
		slotTexture = FileSystem.LoadGfx(raceData._faces[entity.stat.gender])
		if entity.stat.skintone in raceData._skins:
			var skinData : TraitData = raceData._skins[entity.stat.skintone]
			if skinData and not skinData._path.is_empty():
				slotMaterial = FileSystem.LoadPalette(raceData._skins[entity.stat.skintone]._path)

	sprite.set_texture(slotTexture)
	sprite.set_material(slotMaterial)
	LoadSpriteSlot(ActorCommons.Slot.FACE, sprite)

func SetHair():
	var slotName : String = ActorCommons.GetSlotName(ActorCommons.Slot.HAIR)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	var slotTexture : Texture2D = null
	var slotMaterial : Material = null

	if not entity.stat.IsMorph():
		var hairstyleData : TraitData = DB.GetHairstyle(entity.stat.hairstyle) if entity.stat.hairstyle != DB.UnknownHash else null
		var haircolorData : TraitData = DB.GetHaircolor(entity.stat.haircolor) if entity.stat.haircolor != DB.UnknownHash else null
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
		var cell : ItemCell = entity.inventory.equipments[slot] if entity.inventory else (data._equipments[slot] if data else null)
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

	if data:
		var rescaledSlot : int = slot
		if slot >= ActorCommons.Slot.FIRST_MODIFIER and slot < ActorCommons.Slot.LAST_MODIFIER:
			rescaledSlot = slot - ActorCommons.Slot.FIRST_MODIFIER
			if data._customTextures[rescaledSlot]:
				sprite.set_texture(FileSystem.LoadGfx(data._customTextures[rescaledSlot]))
			if data._customShaders[rescaledSlot]:
				sprite.set_material(FileSystem.LoadResource(data._customShaders[rescaledSlot], false))

	LoadSpriteSlot(slot, sprite)

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
		spriteOffset = -1 * int(sprites[ActorCommons.Slot.BODY].offset.y)
	return spriteOffset

#
func Init(data : EntityData):
	Callback.PlugCallback(get_parent().stat.entity_stats_updated, self.UpdateScale)
	sprites.resize(ActorCommons.SlotEquipmentCount + ActorCommons.SlotModifierCount)

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
