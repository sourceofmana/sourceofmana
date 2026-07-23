@tool
extends Resource
class_name EntityData

# Parent entity for inheritance (avoids duplication in .tres files)
@export var _parent : EntityData					= null

@export var _id : int								= DB.UnknownHash
@export var _name : String 							= ""
@export var _spritePreset : PackedScene				= null
@export var _radius : int							= 0
@export var _stats : Dictionary						= ActorCommons.DefaultStats.duplicate()
@export_category("Visual")
@export var _equipment : Array[ItemCell]			= []
@export var _customTexture : Texture2D				= null
@export var _customMaterial : Material				= null
@export var _displayName : bool						= false
@export var _direction : ActorCommons.Direction		= ActorCommons.Direction.UNKNOWN
@export var _state : ActorCommons.State				= ActorCommons.State.UNKNOWN
@export_category("Skills")
@export_flags("Pacifist", "Neutral", "Aggressive", "Immobile", "Follower", "Leader", "Spawner", "Steal", "Flee") var _behaviour : int = AICommons.Behaviour.NEUTRAL
@export var _skills : Dictionary[SkillCell, float]	= {}
@export_category("Drops")
@export var _drops : Dictionary[ItemCell, float]	= {}
@export var _spawns : Dictionary[EntityData, int]	= {}
@export_category("Quests")
@export var _quest : QuestData						= null
@export var _questState : int						= ProgressCommons.UnknownProgress
@export var _questStateMax : int					= ProgressCommons.UnknownProgress
var _questID : int									= DB.UnknownHash
@export_category("Audio")
@export var _stateSFX : Dictionary[ActorCommons.State, AudioStream]	= {}
@export var _alterationSFX : Dictionary[ActorCommons.Alteration, AudioStream]	= {}
@export_category("Flags")
@export var _isBoss : bool							= false

const hashedStats : PackedStringArray				= ["race", "skintone", "hairstyle", "haircolor"]

func IsQuestStateVisible(questState : int) -> bool:
	if _questID == DB.UnknownHash:
		return true
	if _questStateMax != ProgressCommons.UnknownProgress:
		return questState >= _questState and questState <= _questStateMax
	return questState == _questState

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
	merged._spritePreset = _spritePreset if _spritePreset != null else merged._spritePreset
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
	merged._quest = _quest if _quest != null else merged._quest
	merged._questID = merged._quest.id if merged._quest else DB.UnknownHash
	merged._questState = _questState if _questState != ProgressCommons.UnknownProgress else merged._questState
	merged._questStateMax = _questStateMax if _questStateMax != ProgressCommons.UnknownProgress else merged._questStateMax

	# Sfx
	for key : ActorCommons.State in _stateSFX:
		merged._stateSFX[key] = _stateSFX[key]
	for key : ActorCommons.Alteration in _alterationSFX:
		merged._alterationSFX[key] = _alterationSFX[key]

	# Flags
	if _isBoss:
		merged._isBoss = true

	return merged
