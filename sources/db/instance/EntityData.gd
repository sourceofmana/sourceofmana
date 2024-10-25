extends Node
class_name EntityData

@export var _id : int							= -1
@export var _name : String 						= ""
@export var _ethnicity : String					= ""
@export var _collision : String					= ""
@export var _radius : int						= 0
@export var _customTextures : Array[String]		= []
@export var _customShaders : Array[String]		= []
@export var _displayName : bool					= false
@export var _behaviour : int					= AICommons.Behaviour.NEUTRAL
@export var _stats : Dictionary					= {}
@export var _skillSet : Array[int]				= []
@export var _skillProba : Dictionary			= {}
@export var _drops : Array[int]					= []
@export var _dropsProba : Dictionary			= {}
@export var _spawns : Dictionary				= {}

func _init():
	_customTextures.resize(ActorCommons.Slot.COUNT)
	_customShaders.resize(ActorCommons.Slot.COUNT)

static func Create(key : String, result : Dictionary) -> EntityData:
	var entity : EntityData = EntityData.new()
	entity._id = key.to_int()
	entity._name = result.Name
	if "Ethnicity" in result:
		entity._ethnicity = result.Ethnicity
	if "Collision" in result:
		entity._collision = result.Collision
	if "Radius" in result:
		entity._radius = clampi(result.Radius.to_int(), 0, ActorCommons.MaxEntityRadiusSize)
	if "Textures" in result:
		for texture in result.Textures:
			entity._customTextures[ActorCommons.GetSlotID(texture)] = result.Textures[texture]
	if "Shaders" in result:
		for shader in result.Shaders:
			entity._customShaders[ActorCommons.GetSlotID(shader)] = result.Shaders[shader]
	if "DisplayName" in result:
		entity._displayName = result.DisplayName
	if "Behaviour" in result:
		entity._behaviour = AICommons.GetBehaviourFlags(result.Behaviour)
	if "Stat" in result:
		for statName in result.Stat:
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
			entity._spawns[entityName] = result.Spawns[entityName]

	return entity
