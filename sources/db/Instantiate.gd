extends Node
class_name Instantiate

# Entity
static func CreateEntity(actorType : ActorCommons.Type, data : EntityData, nick : String = "", isManaged : bool = false) -> Entity:
	if not data:
		return null

	var actor : Entity = FileSystem.LoadEntityVariant()
	if actor:
		actor._init(actorType, data, nick, isManaged)
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
			if data._direction != ActorCommons.Direction.UNKNOWN:
				actor.currentOrientation = ActorCommons.GetDirectionFromEnum(data._direction)
			actor.spawnInfo = spawn
			actor.playerScriptPath = spawn.player_script
			actor.ownScriptPath = spawn.own_script
		"Monster":
			actor = MonsterAgent.new(ActorCommons.Type.MONSTER, data, nick, true)
			actor.currentOrientation = ActorCommons.GetDirectionFromEnum(data._direction)
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
static func LoadMapData(mapID : int) -> Resource:
	var mapData : FileData = DB.MapsDB.get(mapID, null)
	return FileSystem.LoadMap(Path.MapDataPst + mapData._path + Path.RscExt) if mapData else null

static func LoadMapLayers(mapID : int) -> Node2D:
	var mapData : FileData = DB.MapsDB.get(mapID, null)
	var mapScene : Node2D = FileSystem.LoadMap(Path.MapLayerPst + mapData._path + Path.SceneExt) if mapData else null
	mapScene.set_name(mapData._name)
	return mapScene

static func LoadMapNavigation(mapID : int) -> Object:
	var mapData : FileData = DB.MapsDB.get(mapID, null)
	return FileSystem.LoadMap(Path.MapNavPst + mapData._path + Path.RscExt) if mapData else null
