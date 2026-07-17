extends Node
class_name Instantiate

const EntityScene : PackedScene = preload("res://presets/entities/Entity.tscn")

# Entity
static func CreateEntity(actorType : ActorCommons.Type, data : EntityData, nick : String = "", isManaged : bool = false) -> Entity:
	if not data:
		return null

	var actor : Entity = EntityScene.instantiate()
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
		ActorCommons.Type.NPC:
			actor = NpcAgent.new(ActorCommons.Type.NPC, data, nick, true)
			var npcDir : ActorCommons.Direction = spawn.direction if spawn.direction != ActorCommons.Direction.UNKNOWN else data._direction
			if npcDir != ActorCommons.Direction.UNKNOWN:
				actor.currentOrientation = ActorCommons.GetDirectionFromEnum(npcDir as ActorCommons.Direction)
			if spawn.state != ActorCommons.State.UNKNOWN:
				actor.defaultState = spawn.state as ActorCommons.State
			actor.spawnInfo = spawn
		ActorCommons.Type.MONSTER:
			actor = MonsterAgent.new(ActorCommons.Type.MONSTER, data, nick, true)
			var mobDir : int = spawn.direction if spawn.direction != ActorCommons.Direction.UNKNOWN else data._direction
			actor.currentOrientation = ActorCommons.GetDirectionFromEnum(mobDir as ActorCommons.Direction)
			if spawn.state != ActorCommons.State.UNKNOWN:
				actor.defaultState = spawn.state as ActorCommons.State
			actor.spawnInfo = spawn
		ActorCommons.Type.PLAYER:
			actor = PlayerAgent.new(ActorCommons.Type.PLAYER, data, nick, true)
		_: assert(false, "Trying to create an agent with a wrong type: " + str(spawn.type))
	return actor

# Drop
static func CreateDrop(cell : BaseCell, pos : Vector2) -> Sprite2D:
	var node : Sprite2D = Sprite2D.new()
	node.texture = cell.icon
	node.position = pos
	if cell is ItemCell and cell.shader != null:
		node.material = cell.shader
	return node

# Map
static func LoadMapData(mapID : int) -> MapServerData:
	var mapData : MapData = DB.MapsDB.get(mapID, null)
	return mapData.serverData if mapData else null

static func LoadMapLayers(mapID : int) -> Node2D:
	var mapData : MapData = DB.MapsDB.get(mapID, null)
	if not mapData or not mapData.layers:
		return null
	var mapScene : Node2D = mapData.layers.instantiate()
	mapScene.set_name(mapData._name)
	return mapScene

static func LoadMapNavigation(mapID : int) -> NavigationPolygon:
	var mapData : MapData = DB.MapsDB.get(mapID, null)
	return mapData.navigation if mapData else null
