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

static func CreateEntity(entityType : ActorCommons.Type, entityID : String, nick : String = "") -> Entity:
	var actor : Entity = FileSystem.LoadEntityVariant()
	if actor:
		actor.Init(entityType, entityID, nick)
	return actor

static func CreateAgent(entityTypeStr : String, entityID : String, nick : String = "", scriptPath : String = "") -> BaseAgent:
	var actor : BaseAgent = null
	var entityType : ActorCommons.Type = ActorCommons.Type.NPC
	match entityTypeStr:
		"Npc":
			actor = NpcAgent.new()
			entityType = ActorCommons.Type.NPC
			actor.scriptPath = scriptPath
		"Trigger":
			actor = NpcAgent.new()
			entityType = ActorCommons.Type.NPC
		"Monster":
			actor = MonsterAgent.new()
			entityType = ActorCommons.Type.MONSTER
		"Player":
			actor = PlayerAgent.new()
			entityType = ActorCommons.Type.PLAYER
		_: Util.Assert(false, "Trying to create an agent with a wrong type: " + entityTypeStr)

	if actor:
		actor.Init(entityType, entityID, nick)

	return actor

# Map
static func LoadMapData(mapName : String, ext : String) -> Object:
	var mapPath : String			= DB.GetMapPath(mapName)
	var mapInstance : Object		= FileSystem.LoadMap(mapPath, ext)

	return mapInstance
