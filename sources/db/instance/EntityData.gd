extends Node
class_name EntityData

@export var _id : int							= -1
@export var _name : String 						= ""
@export var _ethnicity : String					= ""
@export var _hairstyle : String					= ""
@export var _navigationAgent : String			= ""
@export var _collision : String					= ""
@export var _customTexture : String				= ""
@export var _displayName : bool					= false
@export var _stats : Dictionary					= {}
@export var _skillSet : Array[SkillData]		= []
@export var _skillProba : Dictionary			= {}

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
	if "Texture" in result:
		entity._customTexture = result.Texture
	if "walkSpeed" in result:
		entity._stats["walkSpeed"] = result.walkSpeed
	if "spirit" in result:
		entity._stats["spirit"] = result.spirit
	if "DisplayName" in result:
		entity._displayName = result.DisplayName
	if "SkillSet" in result:
		for skillSetName in result.SkillSet:
			if DB.SkillsDB.has(skillSetName):
				entity._skillSet.append(DB.SkillsDB[skillSetName])
				entity._skillProba[DB.SkillsDB[skillSetName]] = result.SkillSet[skillSetName]

	return entity
