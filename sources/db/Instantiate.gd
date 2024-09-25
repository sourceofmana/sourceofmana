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
	var data : EntityData = Instantiate.FindEntityReference(entityID)
	assert(data != null, "Could not create the actor: %s" % entityID)
	if not data:
		return null

	var actor : Entity = FileSystem.LoadEntityVariant()
	if actor:
		actor.Init(entityType, data,  entityID if nick.length() == 0 else nick, isManaged)
	return actor

static func CreateAgent(spawn : SpawnObject, data : EntityData, nick : String = "") -> BaseAgent:
	if spawn == null or data == null:
		return null

	var position : Vector2 = WorldNavigation.GetSpawnPosition(spawn.map, spawn, !(data._behaviour & AICommons.Behaviour.IMMOBILE))
	if Vector2i(position) == Vector2i.ZERO:
		return null

	var actor : BaseAgent = null
	var type : ActorCommons.Type = ActorCommons.Type.NPC

	match spawn.type:
		"Npc":
			actor = NpcAgent.new()
			actor.playerScriptPath = spawn.player_script
			actor.ownScriptPath = spawn.own_script
			type = ActorCommons.Type.NPC
		"Monster":
			actor = MonsterAgent.new()
			type = ActorCommons.Type.MONSTER
		"Player":
			actor = PlayerAgent.new()
			type = ActorCommons.Type.PLAYER
		_: assert(false, "Trying to create an agent with a wrong type: " + spawn.type)

	if actor:
		actor.Init(type, data, spawn.name if nick.is_empty() else nick, true)
		actor.spawnInfo = spawn
		actor.position = position

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
