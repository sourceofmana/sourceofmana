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

static func CreateGenericEntity(actor : Actor, entityType : ActorCommons.Type, entityID : String, entityName : String = ""):
	var template : EntityData = FindEntityReference(entityID)
	Util.Assert(template != null and actor != null, "Could not create the entity: %s" % entityID)
	if template and actor:
		actor.type = entityType
		actor.stat.Init(actor, template)
		actor.SetData(template)
		actor.entityName = entityID if entityName.length() == 0 else entityName

static func CreateEntity(entityType : ActorCommons.Type, entityID : String, entityName : String = "") -> BaseEntity:
	var entityInstance : BaseEntity = FileSystem.LoadEntityVariant(entityType)
	CreateGenericEntity(entityInstance, entityType, entityID, entityName)
	return entityInstance

static func CreateAgent(entityTypeStr : String, entityID : String, entityName : String = "") -> BaseAgent:
	var entityInstance : BaseAgent = null
	var entityType : ActorCommons.Type = ActorCommons.Type.NPC
	match entityTypeStr:
		"Npc":
			entityInstance = NpcAgent.new()
			entityType = ActorCommons.Type.NPC
		"Trigger":
			entityInstance = NpcAgent.new()
			entityType = ActorCommons.Type.NPC
		"Monster":
			entityInstance = MonsterAgent.new()
			entityType = ActorCommons.Type.MONSTER
		"Player":
			entityInstance = PlayerAgent.new()
			entityType = ActorCommons.Type.PLAYER
		_: Util.Assert(false, "Trying to create an agent with a wrong type: " + entityTypeStr)
	CreateGenericEntity(entityInstance, entityType, entityID, entityName)
	return entityInstance

# Map
static func LoadMapData(mapName : String, ext : String) -> Object:
	var mapPath : String			= DB.GetMapPath(mapName)
	var mapInstance : Object		= FileSystem.LoadMap(mapPath, ext)

	return mapInstance
