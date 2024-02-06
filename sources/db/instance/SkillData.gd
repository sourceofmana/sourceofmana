extends Node
class_name SkillData

@export var _name : String							= "Unknown"
@export var _icon : Resource						= null
@export var _castPreset : PackedScene				= null
@export var _castTextureOverride : Resource			= null
@export var _castColor : Color						= Color.BLACK
@export var _castTime : float						= 0.0
@export var _skillPreset : PackedScene				= null
@export var _skillColor : Color						= Color.BLACK
@export var _skillTime : float						= 0.0
@export var _projectilePreset : PackedScene			= null
@export var _cooldownTime : float					= 0.0
@export var _state : EntityCommons.State			= EntityCommons.State.IDLE
@export var _mode : Skill.TargetMode				= Skill.TargetMode.SINGLE
@export var _range : int							= 32
@export var _damage : int							= 0
@export var _heal : int								= 0
@export var _repeat : bool							= false

# Stats, must have the same name than their relatives in EntityStats
@export var stamina : int							= 0
@export var mana : int								= 0

static func Create(key : String, result : Dictionary) -> SkillData:
	var skill : SkillData = SkillData.new()
	skill._name = key
	skill._icon = ResourceLoader.load(Path.GfxRsc + result.IconPath)
	if "CastPresetPath" in result:
		skill._castPreset = ResourceLoader.load(Path.EffectsPst + result.CastPresetPath + Path.SceneExt)
	if "CastTextureOverride" in result:
		skill._castTextureOverride = ResourceLoader.load(Path.GfxRsc + result.CastTextureOverride)
	if "CastColor" in result:
		skill._castColor = result.CastColor
	if "CastTime" in result:
		skill._castTime = result.CastTime
	if "SkillPresetPath" in result:
		skill._skillPreset = ResourceLoader.load(Path.EffectsPst + result.SkillPresetPath + Path.SceneExt)
	if "SkillColor" in result:
		skill._skillColor = result.SkillColor
	if "SkillTime" in result:
		skill._skillTime = result.SkillTime
	if "ProjectilePath" in result:
		skill._projectilePreset = ResourceLoader.load(Path.EffectsPst + result.ProjectilePath + Path.SceneExt)
	if "CooldownTime" in result:
		skill._cooldownTime = result.CooldownTime
	if "State" in result:
		skill._state = EntityCommons.State[result.State]
	if "Mode" in result:
		skill._mode = Skill.TargetMode[result.Mode]
	if "Range" in result:
		skill._range = result.Range
	if "Damage" in result:
		skill._damage = result.Damage
	if "Heal" in result:
		skill._heal = result.Heal
	if "Repeat" in result:
		skill._repeat = result.Repeat
	if "StaminaCost" in result:
		skill.stamina = result.StaminaCost
	if "ManaCost" in result:
		skill.mana = result.ManaCost

	return skill
