extends Node
class_name Instantiate

# Entity
static func CreateEntity(entityType : ActorCommons.Type, data : EntityData, nick : String = "", isManaged : bool = false) -> Entity:
	if not data:
		return null

	var actor : Entity = FileSystem.LoadEntityVariant()
	if actor:
		actor._init(entityType, data, nick, isManaged)
	return actor

static func CreateAgent(spawn : SpawnObject, data : EntityData, nick : String = "") -> BaseAgent:
	if spawn == null or data == null:
		return null

	if nick.is_empty():
		nick = data._name

	var actor : BaseAgent = null
	match spawn.type:
		"Npc":
			actor = NpcAgent.new(ActorCommons.Type.NPC, data, nick, true)
			actor.spawnInfo = spawn
			actor.playerScriptPath = spawn.player_script
			actor.ownScriptPath = spawn.own_script
		"Monster":
			actor = MonsterAgent.new(ActorCommons.Type.MONSTER, data, nick, true)
			actor.spawnInfo = spawn
		"Player":
			actor = PlayerAgent.new(ActorCommons.Type.PLAYER, data, nick, true)
		_: assert(false, "Trying to create an agent with a wrong type: " + spawn.type)
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
