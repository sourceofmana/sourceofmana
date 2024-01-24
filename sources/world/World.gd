extends ServiceBase

class_name WorldService

# Types
class Map extends Object:
	var name : String						= ""
	var instances : Array[WorldInstance]			= []
	var spawns : Array[SpawnObject]			= []
	var warps : Array[WarpObject]			= []
	var navPoly : NavigationPolygon			= null
	var mapRID : RID						= RID()
	var regionRID : RID						= RID()
	var spiritOnly : bool					= false

# Vars
var areas : Dictionary						= {}
var defaultSpawn : SpawnObject				= SpawnObject.new()

# Instance init
func LoadData(map : Map):
	var node : Node = Instantiate.LoadMapData(map.name, Path.MapServerExt)
	if node:
		if "spirit_only" in node:
			map.spiritOnly = node.spirit_only
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
					spawnObject.respawn_delay = spawn[5]
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
		CreateInstance(map)

func CreateInstance(map : Map, instanceID : int = 0):
	var inst : WorldInstance = WorldInstance.new()
	inst.id = instanceID
	inst.map = map

	WorldNavigation.CreateInstance(map, inst.get_world_2d().get_navigation_map())
	map.instances.push_back(inst)
	Launcher.Root.add_child.call_deferred(inst)

	for spawn in map.spawns:
		spawn.is_persistant = true
		spawn.map = map
		for i in spawn.count:
			WorldAgent.CreateAgent(spawn, instanceID)

# Getters
func CanWarp(agent : BaseAgent) -> WarpObject:
	var map : Map = WorldAgent.GetMapFromAgent(agent)
	if map:
		for warp in map.warps:
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
		agent.SwitchInputMode(true)
		Spawn(newMap, agent)

func Spawn(map : Map, agent : BaseAgent, instanceID : int = 0):
	Util.Assert(map != null and instanceID < map.instances.size() and agent != null, "Spawn could not proceed, agent or map missing")
	if map and instanceID < map.instances.size() and agent:
		var inst : WorldInstance = map.instances[instanceID]
		Util.Assert(inst != null, "Spawn could not proceed, map instance missing")
		if inst:
			agent.ResetNav()
			if agent.agent:
				agent.agent.set_velocity_forced(Vector2.ZERO)
				agent.agent.set_navigation_map(map.mapRID)
			agent.currentVelocity = Vector2.ZERO
			agent.currentState = EntityCommons.State.IDLE

			WorldAgent.PushAgent(agent, inst)
			Util.OneShotCallback(agent.tree_entered, AgentWarped, [map, inst, agent])

func AgentWarped(map : Map, instance : WorldInstance, agent : BaseAgent):
	if agent == null:
		return

	if agent is PlayerAgent:
		var playerID = Launcher.Network.Server.GetRid(agent)
		if playerID == Launcher.Network.RidUnknown:
			return

		if map.spiritOnly != agent.stat.morphed:
			agent.Morph(false)

		Launcher.Network.WarpPlayer(map.name, playerID)
		for neighbours in WorldAgent.GetNeighboursFromAgent(agent):
			for neighbour in neighbours:
				Launcher.Network.AddEntity(neighbour.get_rid().get_id(), neighbour.agentType, neighbour.GetCurrentShapeID(), neighbour.agentName, neighbour.velocity, neighbour.position, neighbour.currentOrientation, neighbour.currentState, neighbour.currentSkillCastID, playerID)

	Launcher.Network.Server.NotifyInstancePlayers(instance, agent, "AddEntity", [agent.agentType, agent.GetCurrentShapeID(), agent.agentName, agent.velocity, agent.position, agent.currentOrientation, agent.currentState, agent.currentSkillCastID], false)

# Generic
func _post_launch():
	for mapName in Launcher.DB.MapsDB:
		var map : Map = Map.new()
		map.name = mapName
		LoadData(map)
		areas[mapName] = map

	var mapName : String			= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
	defaultSpawn.map				= GetMap(mapName)
	defaultSpawn.spawn_position		= Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP)
	defaultSpawn.type				= "Player"
	defaultSpawn.name				= "Default Entity"

	isInitialized = true
