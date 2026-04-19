@tool
extends Resource
class_name EntityData

## Parent entity for inheritance (avoids duplication in .tres files)
@export var _parent : EntityData					= null

## Unique CRC32 hash.
#
## Once commited to production [b]it must not be changed anymore[/b] or it will mess up the database index.
@export var _id : int								= DB.UnknownHash
## Name of the NPC. E.g "Tulimshar Guard".
@export var _name : String 							= ""
## Can take any file path in [code]presets/entities/*.tres[/code].
@export var _spritePreset : String					= ""
## How far away (in pixels) the player can be to interact with the NPC.
@export var _radius : int							= 0
## Attributes/stats of the NPC. See [BaseStats].
@export var _stats : Dictionary						= ActorCommons.DefaultStats.duplicate()
@export_category("Visual")
## Array of [ItemCell].
@export var _equipment : Array[ItemCell]			= []
## If the NPC has a custom texture, usually located in [code]data/graphics/sprites/npcs[/code].
##
## Takes path that is relative to data/graphics. E.g [code]sprites/npcs/elanore.png[/code]
@export var _customTexture : Texture2D				= null
## Custom material, usually a shader.
@export var _customMaterial : Material				= null
## Whether the entity name tag is displayed.
@export var _displayName : bool						= false
## Default direction the entity will face. Takes [enum ActorCommons.Direction].
@export var _direction : ActorCommons.Direction		= ActorCommons.Direction.UNKNOWN
## Default state. Takes [enum ActorCommons.State].
##
## Useful if you want a NPC e.g sitting down by default.
@export var _state : ActorCommons.State				= ActorCommons.State.UNKNOWN
@export_category("Skills")
@export_flags("Pacifist", "Neutral", "Aggressive", "Immobile", "Follower", "Leader", "Spawner", "Steal") var _behaviour : int = AICommons.Behaviour.NEUTRAL
@export var _skills : Dictionary[SkillCell, float]	= {}
@export_category("Drops")
@export var _drops : Dictionary[ItemCell, float]	= {}
@export var _spawns : Dictionary[EntityData, int]	= {}
@export_category("Quests")
## Set this to an [enum ProgressCommons.Quest] enum to only make the NPC appear when a quest is active.
@export var _questID : int							= ProgressCommons.Quest.UNKNOWN
## Minimum quest state that is required for it to appear.
@export var _questState : int						= ProgressCommons.UnknownProgress
## Maxinum quest state after which the NPC will not show anymore.
@export var _questStateMax : int					= ProgressCommons.UnknownProgress
@export_category("Flags")
## Controls whether or not a big boss health bar will appear when fighting it.
@export var _isBoss : bool							= false

const hashedStats : PackedStringArray				= ["race", "skintone", "hairstyle", "haircolor"]

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
	merged._radius = _radius if _radius != 0 else merged._radius
	merged._customTexture = _customTexture if _customTexture != null else merged._customTexture
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
	if not _skills.is_empty():
		merged._skills = _skills.duplicate()
	for spawn_key in _spawns:
		merged._spawns[spawn_key] = _spawns[spawn_key]

	# Drops
	if not _drops.is_empty():
		merged._drops = _drops.duplicate()

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
		entity._customTexture = FileSystem.LoadGfx(result.Texture)
	if "Material" in result:
		var paletteData : FileData = DB.GetPalette(DB.Palette.SKIN, DB.GetCellHash(result.Material))
		if paletteData:
			entity._customMaterial = FileSystem.LoadPalette(paletteData._path)

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
			assert(DB.HasCellHash(skillName), "Unknown skill '%s' in entity '%s'" % [skillName, entity._name])
			if DB.HasCellHash(skillName):
				var skillCell : SkillCell = DB.GetSkill(DB.GetCellHash(skillName))
				if skillCell:
					entity._skills[skillCell] = result.SkillSet[skillName]
	if "Drops" in result:
		for itemName in result.Drops:
			assert(DB.HasCellHash(itemName), "Unknown drop '%s' in entity '%s'" % [itemName, entity._name])
			if DB.HasCellHash(itemName):
				var dropCell : ItemCell = DB.GetItem(DB.GetCellHash(itemName))
				if dropCell:
					entity._drops[dropCell] = result.Drops[itemName]
	if "Spawns" in result:
		for entityName in result.Spawns:
			var spawnEntity : EntityData = DB.GetEntity(entityName.hash())
			if spawnEntity:
				entity._spawns[spawnEntity] = int(result.Spawns[entityName])
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
