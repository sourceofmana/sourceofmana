extends ServiceBase

class_name WorldService

# Vars
var areas : Dictionary						= {}
var defaultSpawn : SpawnObject				= SpawnObject.new()

# Getters
func CanWarp(agent : BaseAgent) -> WarpObject:
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		for warp in map.warps:
			if warp and Geometry2D.is_point_in_polygon(agent.get_position(), warp.polygon):
				return warp
	return null

func GetMap(mapName : String) -> WorldMap:
	return areas[mapName] if mapName in areas else null

# Core functions
func Warp(agent : BaseAgent, newMap : WorldMap, newPos : Vector2i):
	Util.Assert(newMap != null and agent != null, "Warp could not proceed, agent or current map missing")
	if agent and newMap:
		WorldAgent.PopAgent(agent)
		agent.position = newPos
		agent.SwitchInputMode(true)
		Spawn(newMap, agent)

func Spawn(map : WorldMap, agent : BaseAgent, instanceID : int = 0):
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

func AgentWarped(map : WorldMap, instance : WorldInstance, agent : BaseAgent):
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
				Launcher.Network.AddEntity(neighbour.get_rid().get_id(), neighbour.GetEntityType(), neighbour.GetCurrentShapeID(), neighbour.entityName, neighbour.velocity, neighbour.position, neighbour.currentOrientation, neighbour.currentState, neighbour.currentSkillCastID, playerID)

	Launcher.Network.Server.NotifyInstancePlayers(instance, agent, "AddEntity", [agent.GetEntityType(), agent.GetCurrentShapeID(), agent.entityName, agent.velocity, agent.position, agent.currentOrientation, agent.currentState, agent.currentSkillCastID], false)

# Generic
func _post_launch():
	for mapName in Launcher.DB.MapsDB:
		areas[mapName] = WorldMap.Create(mapName)

	var mapName : String			= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
	defaultSpawn.map				= GetMap(mapName)
	defaultSpawn.spawn_position		= Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP)
	defaultSpawn.type				= "Player"
	defaultSpawn.name				= "Default Entity"

	isInitialized = true
