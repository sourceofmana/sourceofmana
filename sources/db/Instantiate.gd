extends Node
class_name Instantiate

# Entity
static func FindEntityReference(entityID : String) -> Object:
	var ref : Object = null
	for entityDB in Launcher.DB.EntitiesDB:
		if entityDB == entityID || Launcher.DB.EntitiesDB[entityDB]._name == entityID:
			ref = Launcher.DB.EntitiesDB[entityDB]
			break
	return ref

static func CreateGenericEntity(entityInstance : CharacterBody2D, entityType : String, entityID : String, entityName : String = ""):
	var template = FindEntityReference(entityID)
	Util.Assert(template and entityInstance, "Could not create the entity: %s" % entityID)
	if template and entityInstance:
		entityInstance.SetData(template)
		entityInstance.SetKind(entityType, entityID, entityName)

static func CreateEntity(entityType : String, entityID : String, entityName : String = "") -> BaseEntity:
	var entityInstance : BaseEntity = FileSystem.LoadEntity(entityType)
	CreateGenericEntity(entityInstance, entityType, entityID, entityName)
	return entityInstance

static func CreateAgent(entityType : String, entityID : String, entityName : String = "") -> BaseAgent:
	var entityInstance : BaseAgent = null
	match entityType:
		"Npc": entityInstance = NpcAgent.new()
		"Trigger": entityInstance = NpcAgent.new()
		"Monster": entityInstance = MonsterAgent.new()
		"Player": entityInstance = PlayerAgent.new()
		_: Util.Assert(false, "Trying to create an agent with a wrong type: " + entityType)
	CreateGenericEntity(entityInstance, entityType, entityID, entityName)
	return entityInstance

# Map
static func LoadMapData(mapName : String, ext : String) -> Object:
	var mapPath : String			= Launcher.DB.GetMapPath(mapName)
	var mapInstance : Object		= FileSystem.LoadMap(mapPath, ext)

	return mapInstance
