extends Node
class_name EntityData

@export var _id : int							= -1
@export var _name : String 						= ""
@export var _ethnicity : String					= ""
@export var _hairstyle : String					= ""
@export var _navigationAgent : String			= ""
@export var _collision : String					= ""
@export var _radius : int						= 0
@export var _customTextures : Array[String]		= []
@export var _customShaders : Array[String]		= []
@export var _displayName : bool					= false
@export var _stats : Dictionary					= {}
@export var _skillSet : Array[int]				= []
@export var _skillProba : Dictionary			= {}

func _init():
	_customTextures.resize(ActorCommons.Slot.COUNT)
	_customShaders.resize(ActorCommons.Slot.COUNT)

static func Create(key : String, result : Dictionary) -> EntityData:
	var entity : EntityData = EntityData.new()
	entity._id = key.to_int()
	entity._name = result.Name
	if "Ethnicity" in result:
		entity._ethnicity = result.Ethnicity
	if "Hairstyle" in result:
		entity._hairstyle = result.Hairstyle
	if "NavigationAgent" in result:
		entity._navigationAgent = result.NavigationAgent
	if "Collision" in result:
		entity._collision = result.Collision
	if "Radius" in result:
		entity._radius = result.Radius
	if "Textures" in result:
		for texture in result.Textures:
			entity._customTextures[ActorCommons.GetSlotID(texture)] = result.Textures[texture]
	if "Shaders" in result:
		for shader in result.Shaders:
			entity._customShaders[ActorCommons.GetSlotID(shader)] = result.Shaders[shader]
	if "DisplayName" in result:
		entity._displayName = result.DisplayName
	if "Stat" in result:
		for statName in result.Stat:
			entity._stats[statName] = result.Stat[statName]
	if "SkillSet" in result:
		for skillSetName in result.SkillSet:
			var skillSetID : int = int(skillSetName)
			if DB.SkillsDB.has(skillSetID):
				entity._skillSet.append(skillSetID)
				entity._skillProba[skillSetID] = result.SkillSet[skillSetName]

	return entity
