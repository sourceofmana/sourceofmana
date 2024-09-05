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

static func CreateEntity(entityType : ActorCommons.Type, entityID : String, nick : String = "", isManaged : bool = false) -> Entity:
	var actor : Entity = FileSystem.LoadEntityVariant()
	if actor:
		actor.Init(entityType, entityID, nick, isManaged)
	return actor

static func CreateAgent(entityTypeStr : String, entityID : String, nick : String = "", playerScriptPath : String = "", ownScriptPath : String = "") -> BaseAgent:
	var actor : BaseAgent = null
	var entityType : ActorCommons.Type = ActorCommons.Type.NPC
	match entityTypeStr:
		"Npc":
			actor = NpcAgent.new()
			entityType = ActorCommons.Type.NPC
			actor.playerScriptPath = playerScriptPath
			actor.ownScriptPath = ownScriptPath
		"Monster":
			actor = MonsterAgent.new()
			entityType = ActorCommons.Type.MONSTER
		"Player":
			actor = PlayerAgent.new()
			entityType = ActorCommons.Type.PLAYER
		_: Util.Assert(false, "Trying to create an agent with a wrong type: " + entityTypeStr)

	if actor:
		actor.Init(entityType, entityID, nick, true)

	return actor

# Drop
static func CreateDrop(cell : BaseCell, pos : Vector2) -> Sprite2D:
	var node : Sprite2D = Sprite2D.new()
	node.texture = cell.icon
	node.position = pos
	return node

# Map
static func LoadMapData(mapName : String, ext : String) -> Object:
	var mapPath : String			= DB.GetMapPath(mapName)
	var mapInstance : Object		= FileSystem.LoadMap(mapPath, ext)

	return mapInstance
