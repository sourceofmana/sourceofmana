extends Resource
class_name EntityData

@export var _id : int							= DB.UnknownHash
@export var _name : String 						= ""
@export var _spritePreset : String				= ""
@export var _collision : String					= ""
@export var _radius : int						= 0
@export var _equipment : Array[ItemCell]		= []
@export var _customTextures : Array[String]		= []
@export var _customShaders : Array[FileData]	= []
@export var _displayName : bool					= false
@export var _behaviour : int					= AICommons.Behaviour.NEUTRAL
@export var _stats : Dictionary					= ActorCommons.DefaultStats.duplicate()
@export var _skillSet : Array[int]				= []
@export var _skillProba : Dictionary[int, float]= {}
@export var _drops : Array[int]					= []
@export var _dropsProba : Dictionary[int, float]= {}
@export var _spawns : Dictionary[int, int]		= {}

const hashedStats : PackedStringArray			= ["race", "skintone", "hairstyle", "haircolor"]

func _init():
	_customTextures.resize(ActorCommons.SlotModifierCount)
	_customShaders.resize(ActorCommons.SlotModifierCount)
	_equipment.resize(ActorCommons.SlotEquipmentCount)

static func Create(result : Dictionary) -> EntityData:
	var entity : EntityData = EntityData.new()
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
	if "Textures" in result:
		for texture in result.Textures:
			entity._customTextures[ActorCommons.GetSlotID(texture) - ActorCommons.Slot.FIRST_MODIFIER] = result.Textures[texture]
	if "Shaders" in result:
		for shader in result.Shaders:
			var paletteId : int = DB.GetCellHash(result.Shaders[shader])
			entity._customShaders[ActorCommons.GetSlotID(shader) - ActorCommons.Slot.FIRST_MODIFIER] = DB.GetPalette(DB.Palette.SKIN, paletteId)

	if "DisplayName" in result:
		entity._displayName = result.DisplayName
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

	return entity
