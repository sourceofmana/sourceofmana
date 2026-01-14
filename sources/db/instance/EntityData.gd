extends Resource
class_name EntityData

@export var _id : int							= DB.UnknownHash
@export var _name : String 						= ""
@export var _spritePreset : String				= ""
@export var _collision : String					= ""
@export var _radius : int						= 0
@export var _equipment : Array[ItemCell]		= []
@export var _customTexture : String				= ""
@export var _customMaterial : FileData			= null
@export var _displayName : bool					= false
@export var _direction : ActorCommons.Direction	= ActorCommons.Direction.UNKNOWN
@export var _state : ActorCommons.State			= ActorCommons.State.UNKNOWN
@export var _behaviour : AICommons.Behaviour	= AICommons.Behaviour.NEUTRAL
@export var _stats : Dictionary					= ActorCommons.DefaultStats.duplicate()
@export var _skillSet : PackedInt64Array		= []
@export var _skillProba : Dictionary[int, float]= {}
@export var _drops : PackedInt64Array			= []
@export var _dropsProba : Dictionary[int, float]= {}
@export var _spawns : Dictionary[int, int]		= {}

const hashedStats : PackedStringArray			= ["race", "skintone", "hairstyle", "haircolor"]

func _init():
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

	return entity
