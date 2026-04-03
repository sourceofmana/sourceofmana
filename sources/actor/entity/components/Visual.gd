extends Node2D
class_name EntityVisual

#
signal spriteOffsetUpdate

#
@onready var entity : Entity				= get_parent()

var preset : Node2D							= null
var animation : AnimationPlayer				= null
var animationTree : AnimationTree			= null
var sprites : Array[Sprite2D]				= []

var previousOrientation : Vector2			= Vector2.ZERO
var previousState : ActorCommons.State		= ActorCommons.State.UNKNOWN

var blendSpacePaths : Array[String]			= []
var walkTimeScalePath : String				= ""
var attackTimeScalePath : String			= ""

var equipmentEffects : Array[Node2D]		= []
var skillCastID : int						= DB.UnknownHash
var attackAnimLength : float				= 1.0
var originalAnimationLib : AnimationLibrary	= null
var defaultHframes : Dictionary				= {}
var defaultVframes : Dictionary				= {}

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
	equipmentEffects.fill(null)
	preset = null
	originalAnimationLib = null

func LoadData(data : EntityData):
	ResetData()

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
					SetHair(false)
				elif slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT:
					SetEquipment(slot, data, false)

	ApplyAnimationOverrides()
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

func SetHair(applyOverrides : bool = true):
	var slotName : String = ActorCommons.GetSlotName(ActorCommons.Slot.HAIR)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	var slot : int = ActorCommons.Slot.HAIR
	if slot not in defaultHframes:
		defaultHframes[slot] = sprite.hframes
		defaultVframes[slot] = sprite.vframes

	var slotTexture : Texture2D = null
	var slotMaterial : Material = null
	var hairstyleData : HairstyleData = null

	if not entity.stat.IsMorph():
		hairstyleData = DB.GetHairstyle(entity.stat.hairstyle) if entity.stat.hairstyle != DB.UnknownHash else null
		var haircolorData : FileData = DB.GetPalette(DB.Palette.HAIR, entity.stat.haircolor) if entity.stat.haircolor != DB.UnknownHash else null
		if hairstyleData != null and haircolorData != null:
			slotTexture = FileSystem.LoadGfx(hairstyleData._path)
			slotMaterial = FileSystem.LoadPalette(haircolorData._path)

	sprite.set_texture(slotTexture)
	sprite.set_material(slotMaterial)

	if hairstyleData and hairstyleData._spriteHframes > 0:
		sprite.hframes = hairstyleData._spriteHframes
		sprite.vframes = max(1, hairstyleData._spriteVframes)
	else:
		sprite.hframes = defaultHframes[slot]
		sprite.vframes = defaultVframes[slot]

	LoadSpriteSlot(slot, sprite)
	if applyOverrides:
		ApplyAnimationOverrides()

func SetEquipment(slot : int, data : EntityData = null, applyOverrides : bool = true):
	var slotName : String = ActorCommons.GetSlotName(slot)
	var sprite : Sprite2D = preset.get_node_or_null(slotName)
	if not sprite:
		return

	if slot not in defaultHframes:
		defaultHframes[slot] = sprite.hframes
		defaultVframes[slot] = sprite.vframes

	var slotTexture : Texture2D = null
	var slotMaterial : Material = null
	var cell : ItemCell = null

	if not entity.stat.IsMorph():
		cell = entity.inventory.equipment[slot] if entity.inventory else (data._equipment[slot] if data else null)
		if cell != null:
			slotTexture = cell.textures[entity.stat.gender]
			slotMaterial = cell.shader

	sprite.set_texture(slotTexture)
	sprite.set_material(slotMaterial)

	if cell and cell.spriteHframes > 0:
		sprite.hframes = cell.spriteHframes
		sprite.vframes = max(1, cell.spriteVframes)
	else:
		sprite.hframes = defaultHframes[slot]
		sprite.vframes = defaultVframes[slot]

	SetEquipmentMetadata(slot, cell)
	LoadSpriteSlot(slot, sprite)
	if applyOverrides:
		ApplyAnimationOverrides()

func SetEquipmentMetadata(slot : int, cell : ItemCell):
	if equipmentEffects[slot]:
		equipmentEffects[slot].queue_free()
		equipmentEffects[slot] = null
	if cell and cell.has_meta("light_radius"):
		var light : LightSource = FileSystem.LoadEffect("LightSource")
		if light:
			light.radius = cell.get_meta("light_radius")
			if cell.has_meta("light_color"):
				light.color = cell.get_meta("light_color")
			equipmentEffects[slot] = light
			add_child.call_deferred(light)

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

	blendSpacePaths.resize(ActorCommons.State.COUNT)
	blendSpacePaths.fill("")
	walkTimeScalePath = ""
	attackTimeScalePath = ""

	for i in ActorCommons.State.COUNT:
		var stateName : String		= ActorCommons.GetStateName(i)
		var blendSpace : String		= "parameters/%s/BlendSpace2D/blend_position" % [stateName]

		if blendSpace in animationTree:
			blendSpacePaths[i] = blendSpace

		# Only set dynamic time scale for attack and walk as other can stay static
		if i == ActorCommons.State.WALK:
			var timeScale : String = "parameters/%s/TimeScale/scale" % [stateName]
			if timeScale in animationTree:
				walkTimeScalePath = timeScale
		elif i == ActorCommons.State.ATTACK:
			var timeScale : String = "parameters/%s/TimeScale/scale" % [stateName]
			if timeScale in animationTree:
				attackTimeScalePath = timeScale

func UpdateScale():
	if not animationTree:
		return

	if not walkTimeScalePath.is_empty():
		animationTree[walkTimeScalePath] = Formula.GetWalkRatio(entity.stat)
	if not attackTimeScalePath.is_empty() and entity.stat.current.castAttackDelay > 0:
		animationTree[attackTimeScalePath] = attackAnimLength / entity.stat.current.castAttackDelay

func ResetAnimationValue():
	if not animationTree:
		return

	LoadAnimationPaths()
	UpdateScale()
	RefreshTree()
	Refresh.call_deferred()

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
	if previousState >= 0:
		var blendPath : String = blendSpacePaths[previousState]
		if not blendPath.is_empty():
			animationTree[blendPath] = previousOrientation

		if resetOnTeleport:
			animationTree[ActorCommons.playbackParameter].travel(ActorCommons.STATE_NAMES[previousState], true)

			# Random default offset for IDLE state of [0;1] second, need to call twice for the AnimationTree to properly apply it
			if previousState == ActorCommons.State.IDLE or previousState == ActorCommons.State.SIT:
				var randValue : float = randf()
				animationTree.advance(randValue)
				animationTree.advance(randValue)

func Refresh():
	if not animationTree or not animationTree.is_inside_tree():
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

#
func CollectAnimationOverrides() -> Array[AnimationLibrary]:
	var allOverrides : Array[AnimationLibrary] = []

	for slot in range(ActorCommons.Slot.FIRST_EQUIPMENT, ActorCommons.Slot.LAST_EQUIPMENT):
		var cell : ItemCell = null
		if entity.inventory:
			cell = entity.inventory.equipment[slot]
		elif entity.data:
			cell = entity.data._equipment[slot]
		if cell and cell.animationOverrides:
			allOverrides.append(cell.animationOverrides)

	if entity.stat.hairstyle != DB.UnknownHash:
		var hairstyleData : HairstyleData = DB.GetHairstyle(entity.stat.hairstyle)
		if hairstyleData and hairstyleData._animationOverrides:
			allOverrides.append(hairstyleData._animationOverrides)

	return allOverrides

func ApplyAnimationOverrides():
	if not animation:
		return

	var allOverrides : Array[AnimationLibrary] = CollectAnimationOverrides()

	if allOverrides.is_empty():
		if originalAnimationLib:
			animation.remove_animation_library("")
			animation.add_animation_library("", originalAnimationLib)
			originalAnimationLib = null
		return

	if not originalAnimationLib:
		originalAnimationLib = animation.get_animation_library("")

	var lib : AnimationLibrary = originalAnimationLib.duplicate(true)

	for overrideLib in allOverrides:
		for animName in overrideLib.get_animation_list():
			if not lib.has_animation(animName):
				continue

			var baseAnim : Animation = lib.get_animation(animName)
			var overrideAnim : Animation = overrideLib.get_animation(animName)
			for trackIdx in overrideAnim.get_track_count():
				var trackPath : NodePath = overrideAnim.track_get_path(trackIdx)
				var trackType : Animation.TrackType = overrideAnim.track_get_type(trackIdx)
				var baseTrackIdx : int = baseAnim.find_track(trackPath, trackType)
				if baseTrackIdx < 0:
					continue

				while baseAnim.track_get_key_count(baseTrackIdx) > 0:
					baseAnim.track_remove_key(baseTrackIdx, 0)
				for keyIdx in overrideAnim.track_get_key_count(trackIdx):
					baseAnim.track_insert_key(
						baseTrackIdx,
						overrideAnim.track_get_key_time(trackIdx, keyIdx),
						overrideAnim.track_get_key_value(trackIdx, keyIdx),
						overrideAnim.track_get_key_transition(trackIdx, keyIdx)
					)

	animation.remove_animation_library("")
	animation.add_animation_library("", lib)

#
func _notification(what : int):
	if what == NOTIFICATION_ENTER_TREE and animationTree:
		Refresh.call_deferred()

func _init():
	sprites.resize(ActorCommons.SlotEquipmentCount + ActorCommons.SlotModifierCount)
	equipmentEffects.resize(ActorCommons.State.COUNT)
