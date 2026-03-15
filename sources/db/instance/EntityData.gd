@tool
extends Resource
class_name EntityData

# Parent entity for inheritance (avoids duplication in .tres files)
@export var _parent : EntityData				= null

@export var _id : int							= DB.UnknownHash
@export var _name : String 						= ""
@export var _spritePreset : String				= ""
@export var _collision : String					= ""
@export var _radius : int						= 0
@export var _stats : Dictionary					= ActorCommons.DefaultStats.duplicate()
@export_category("Visual")
@export var _equipment : Array[ItemCell]		= []
@export var _customTexture : String				= ""
@export var _customMaterial : FileData			= null
@export var _displayName : bool					= false
@export var _direction : ActorCommons.Direction	= ActorCommons.Direction.UNKNOWN
@export var _state : ActorCommons.State			= ActorCommons.State.UNKNOWN
@export_category("Skills")
@export var _behaviour : AICommons.Behaviour	= AICommons.Behaviour.NEUTRAL
@export var _skillSet : PackedInt64Array		= []
@export var _skillProba : Dictionary[int, float]= {}
@export_category("Drops")
@export var _drops : PackedInt64Array			= []
@export var _dropsProba : Dictionary[int, float]= {}
@export var _spawns : Dictionary[int, int]		= {}
@export_category("Quests")
@export var _questID : int						= ProgressCommons.Quest.UNKNOWN
@export var _questState : int					= ProgressCommons.UnknownProgress
@export var _questStateMax : int				= ProgressCommons.CompletedProgress
@export_category("Flags")
@export var _isBoss : bool						= false

const hashedStats : PackedStringArray			= ["race", "skintone", "hairstyle", "haircolor"]

func _init():
	_equipment.resize(ActorCommons.SlotEquipmentCount)

# Merge with parent to get final values (used when loading from .tres with parent references)
func GetMergedEntity() -> EntityData:
	if not _parent:
		return self

	# Recursively merge parent (in case parent also has a parent)
	var merged : EntityData = _parent.GetMergedEntity().duplicate(true)
	merged._id = _id if _id != DB.UnknownHash else _name.hash()
	merged._name = _name if _name != "" else merged._name
	merged._spritePreset = _spritePreset if _spritePreset != "" else merged._spritePreset
	merged._collision = _collision if _collision != "" else merged._collision
	merged._radius = _radius if _radius != 0 else merged._radius
	merged._customTexture = _customTexture if _customTexture != "" else merged._customTexture
	merged._customMaterial = _customMaterial if _customMaterial != null else merged._customMaterial
	merged._displayName = _displayName if _displayName != false else merged._displayName
	merged._direction = _direction if _direction != ActorCommons.Direction.UNKNOWN else merged._direction
	merged._state = _state if _state != ActorCommons.State.UNKNOWN else merged._state
	merged._behaviour = _behaviour if _behaviour != AICommons.Behaviour.NEUTRAL else merged._behaviour

	# Stats
	for stat_key in _stats:
		merged._stats[stat_key] = _stats[stat_key]

	# Equipments
	for i in _equipment.size():
		if _equipment[i] != null:
			merged._equipment[i] = _equipment[i]

	# Skills
	if not _skillSet.is_empty() or not _skillProba.is_empty():
		if not _skillSet.is_empty():
			merged._skillSet = _skillSet.duplicate()
		if not _skillProba.is_empty():
			merged._skillProba = _skillProba.duplicate()
	for spawn_key in _spawns:
		merged._spawns[spawn_key] = _spawns[spawn_key]

	# Drops
	if not _drops.is_empty() or not _dropsProba.is_empty():
		if not _drops.is_empty():
			merged._drops = _drops.duplicate()
		if not _dropsProba.is_empty():
			merged._dropsProba = _dropsProba.duplicate()

	# Quest
	merged._questID = _questID if _questID != ProgressCommons.Quest.UNKNOWN else merged._questID
	merged._questState = _questState if _questState != ProgressCommons.UnknownProgress else merged._questState
	merged._questStateMax = _questStateMax if _questStateMax != ProgressCommons.UnknownProgress else merged._questStateMax

	# Flags
	if _isBoss:
		merged._isBoss = true

	return merged

static func Create(result : Dictionary) -> EntityData:
	var parent : EntityData = null
	if "Parent" in result:
		parent = DB.GetEntity(result.Parent.hash())

	var entity : EntityData = parent.duplicate(true) if parent else EntityData.new()
	entity._id = result.Name.hash()
	entity._name = result.Name
	if "SpritePreset" in result:
		entity._spritePreset = result.SpritePreset
	if "Collision" in result:
		entity._collision = result.Collision
	if "Radius" in result:
		entity._radius = clampi(result.Radius.to_int(), 0, ActorCommons.MaxEntityRadiusSize)
	if "Equipment" in result:
		for itemName in result.Equipment:
			var itemID : int = DB.GetCellHash(itemName)
			if itemID != DB.UnknownHash:
				var itemCell : ItemCell = DB.GetItem(itemID)
				if itemCell and itemCell.slot != ActorCommons.Slot.NONE:
					entity._equipment[itemCell.slot] = itemCell
	if "Texture" in result:
		entity._customTexture = result.Texture
	if "Material" in result:
		var paletteId : int = DB.GetCellHash(result.Material)
		entity._customMaterial = DB.GetPalette(DB.Palette.SKIN, paletteId)

	if "DisplayName" in result:
		entity._displayName = result.DisplayName
	if "Direction" in result:
		entity._direction = ActorCommons.Direction.get(result.Direction, entity._direction)
	if "State" in result:
		entity._state = ActorCommons.State.get(result.State, entity._state)
	if "Behaviour" in result:
		entity._behaviour = AICommons.GetBehaviourFlags(result.Behaviour)
	if "Stat" in result:
		for statName in result.Stat:
			if statName in hashedStats:
				entity._stats[statName] = result.Stat[statName].hash()
			elif statName == "gender":
				entity._stats[statName] = ActorCommons.GetGenderID(result.Stat[statName])
			else:
				entity._stats[statName] = result.Stat[statName]
	if "SkillSet" in result:
		for skillName in result.SkillSet:
			var skillID : int = DB.GetCellHash(skillName)
			if DB.SkillsDB.has(skillID):
				entity._skillSet.append(skillID)
				entity._skillProba[skillID] = result.SkillSet[skillName]
	if "Drops" in result:
		for itemName in result.Drops:
			var itemID : int = DB.GetCellHash(itemName)
			if DB.ItemsDB.has(itemID):
				entity._drops.append(itemID)
				entity._dropsProba[itemID] = result.Drops[itemName]
	if "Spawns" in result:
		for entityName in result.Spawns:
			var entityID : int = entityName.hash()
			entity._spawns[entityID] = int(result.Spawns[entityName])
	if "IsBoss" in result:
		entity._isBoss = bool(result.IsBoss)
	if "QuestFilter" in result:
		for questName in result.QuestFilter:
			entity._questID = ProgressCommons.Quest.get(questName, ProgressCommons.Quest.UNKNOWN)
			var questValue : Variant = result.QuestFilter[questName]
			if questValue is Array and questValue.size() == 2:
				entity._questState = ProgressCommons.GetQuestStateID(entity._questID, questValue[0])
				entity._questStateMax = ProgressCommons.GetQuestStateID(entity._questID, questValue[1])
			else:
				entity._questState = ProgressCommons.GetQuestStateID(entity._questID, questValue)

	return entity
