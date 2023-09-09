extends Node2D

class_name World

# Types
class Instance extends SubViewport:
	var id : int							= 0
	var npcs : Array[BaseAgent]				= []
	var mobs : Array[BaseAgent]				= []
	var players : Array[BaseAgent]			= []
	var map : Map							= null

class Map:
	var name : String						= ""
	var instances : Array[Instance]			= []
	var spawns : Array[SpawnObject]			= []
	var warps : Array[WarpObject]			= []
	var nav_poly : NavigationPolygon		= null
	var mapRID : RID						= RID()
	var regionRID : RID						= RID()

# Vars
var areas : Dictionary						= {}
var defaultSpawn : SpawnObject				= SpawnObject.new()

# Instance init
func LoadData(map : Map):
	var node : Node = Instantiate.LoadMapData(map.name, Launcher.Path.MapServerExt)
	if node:
		if "spawns" in node:
			for spawn in node.spawns:
				Util.Assert(spawn != null, "Warp format is not supported")
				if spawn:
					var spawnObject = SpawnObject.new()
					spawnObject.count = spawn[0]
					spawnObject.name = spawn[1]
					spawnObject.type = spawn[2]
					spawnObject.spawn_position = spawn[3]
					spawnObject.spawn_offset = spawn[4]
					spawnObject.is_global = spawnObject.spawn_position < Vector2i.LEFT
					map.spawns.append(spawnObject)
		if "warps" in node:
			for warp in node.warps:
				Util.Assert(warp != null, "Warp format is not supported")
				if warp:
					var warpObject = WarpObject.new()
					warpObject.destinationMap = warp[0]
					warpObject.destinationPos = warp[1]
					warpObject.polygon = warp[2]
					map.warps.append(warpObject)
		WorldNavigation.LoadData(map)

func CreateInstance(map : Map, instanceID : int = 0):
	var inst : Instance = Instance.new()
	WorldNavigation.CreateInstance(map, inst.get_world_2d().get_navigation_map())

	inst.disable_3d = true
	inst.gui_disable_input = true
	inst.name = map.name
	inst.id = instanceID
	inst.map = map
	if inst.id > 0:
		inst.name += "_" + str(inst.id)
	map.instances.push_back(inst)

	for spawn in map.spawns:
		spawn.is_persistant = true
		spawn.map = map

		for i in spawn.count:
			WorldAgent.CreateAgent(spawn, instanceID)

	Launcher.Root.call_deferred("add_child", inst)

# Getters
func CanWarp(agent : BaseAgent) -> WarpObject:
	var prevMap : Object = WorldAgent.GetMapFromAgent(agent)
	if prevMap:
		for warp in prevMap.warps:
			if warp and Geometry2D.is_point_in_polygon(agent.get_position(), warp.polygon):
				return warp
	return null

func GetMap(mapName : String) -> Map:
	return areas[mapName] if mapName in areas else null

# Core functions
func Warp(agent : BaseAgent, newMap : Map, newPos : Vector2i):
	Util.Assert(newMap != null and agent != null, "Warp could not proceed, agent or current map missing")
	if agent and newMap:
		WorldAgent.PopAgent(agent)
		agent.position = newPos
		Spawn(newMap, agent)

func Spawn(map : Map, agent : BaseAgent, instanceID : int = 0):
	Util.Assert(map != null and instanceID < map.instances.size() and agent != null, "Spawn could not proceed, agent or map missing")
	if map and instanceID < map.instances.size() and agent:
		var inst : Instance = map.instances[instanceID]
		Util.Assert(inst != null, "Spawn could not proceed, map instance missing")
		if inst:
			agent.ResetNav()
			if agent.agent:
				agent.agent.set_velocity_forced(Vector2.ZERO)
				agent.agent.set_navigation_map(map.mapRID)

			WorldAgent.PushAgent(agent, inst)
			if agent is PlayerAgent:
				var agentID = Launcher.Network.Server.GetRid(agent)
				if agentID != Launcher.Network.RidUnknown:
					Util.OneShotCallback(agent.tree_entered, Launcher.Network.WarpPlayer, [map.name, agentID])

# Generic
func _post_launch():
	for mapName in Launcher.DB.MapsDB:
		var map : Map = Map.new()
		map.name = mapName
		LoadData(map)
		CreateInstance(map)
		areas[mapName] = map

	var mapName : String			= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
	defaultSpawn.map				= Launcher.World.GetMap(mapName)
	defaultSpawn.spawn_position		= Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP)
	defaultSpawn.type				= "Player"
	defaultSpawn.name				= "Default Entity"

func _physics_process(_dt : float):
	for map in areas.values():
		for instance in map.instances:
			if instance.players.size() > 0:
				for agent in instance.npcs:
					if agent:
						AI.Update(agent, map)
						agent._internal_process()

				for agent in instance.mobs:
					if agent:
						AI.Update(agent, map)
						agent._internal_process()

				for agent in instance.players:
					if agent:
						agent._internal_process()
