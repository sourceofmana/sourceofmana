extends Node
class_name Instantiate

# Entity
static func FindEntityReference(entityID : String) -> EntityData:
	var ref : EntityData = null
	for entityDB in DB.EntitiesDB:
		if entityDB == entityID || DB.EntitiesDB[entityDB]._name == entityID:
			ref = DB.EntitiesDB[entityDB]
			break
	return ref

static func CreateGenericEntity(entityInstance : CharacterBody2D, entityID : String, entityName : String = ""):
	var template : EntityData = FindEntityReference(entityID)
	Util.Assert(template != null and entityInstance != null, "Could not create the entity: %s" % entityID)
	if template and entityInstance:
		entityInstance.stat.Init(template)
		entityInstance.SetData(template)
		entityInstance.entityName = entityID if entityName.length() == 0 else entityName

static func CreateEntity(entityType : EntityCommons.Type, entityID : String, entityName : String = "") -> BaseEntity:
	var entityPreset : String = ""
	match entityType:
		EntityCommons.Type.PLAYER: entityPreset = "Player"
		EntityCommons.Type.MONSTER: entityPreset = "Monster"
		EntityCommons.Type.NPC: entityPreset = "Npc"
		_: Util.Assert(false, "Trying to create an entity with a wrong type: " + str(entityType))

	var entityInstance : BaseEntity = FileSystem.LoadEntityVariant(entityPreset)
	CreateGenericEntity(entityInstance, entityID, entityName)
	return entityInstance

static func CreateAgent(entityType : String, entityID : String, entityName : String = "") -> BaseAgent:
	var entityInstance : BaseAgent = null
	match entityType:
		"Npc": entityInstance = NpcAgent.new()
		"Trigger": entityInstance = NpcAgent.new()
		"Monster": entityInstance = MonsterAgent.new()
		"Player": entityInstance = PlayerAgent.new()
		_: Util.Assert(false, "Trying to create an agent with a wrong type: " + entityType)
	CreateGenericEntity(entityInstance, entityID, entityName)
	return entityInstance

# Map
static func LoadMapData(mapName : String, ext : String) -> Object:
	var mapPath : String			= DB.GetMapPath(mapName)
	var mapInstance : Object		= FileSystem.LoadMap(mapPath, ext)

	return mapInstance
