extends Node
class_name WorldAgent

static var agents : Dictionary						= {}
static var defaultSpawnLocation : SpawnObject		= SpawnObject.new()

# From Agent getters
static func GetInstanceFromAgent(agent : BaseAgent) -> SubViewport:
	return agent.get_parent()

static func GetMapFromAgent(agent : BaseAgent) -> WorldMap:
	var map : WorldMap = null
	var inst : WorldInstance = GetInstanceFromAgent(agent)
	if inst:
		assert(inst.map != null, "Agent's base map is incorrect, instance is not referenced inside a map")
		map = inst.map
	return map

static func GetNeighboursFromAgent(checkedAgent : BaseAgent) -> Array[Array]:
	var neighbours : Array[Array] = []
	var instance : WorldInstance = GetInstanceFromAgent(checkedAgent)
	if instance:
		neighbours.append(instance.npcs)
		neighbours.append(instance.mobs)
		neighbours.append(instance.players)
	return neighbours

# Basic Agent container handling
static func GetAgent(agentID : int) -> BaseAgent:
	var agent : BaseAgent = null
	if agents.has(agentID):
		agent = agents.get(agentID)
	return agent

static func AddAgent(agent : BaseAgent):
	assert(agent != null, "Agent is null, can't add it")
	if agent and not agents.has(agent.get_rid().get_id()):
		agents[agent.get_rid().get_id()] = agent

static func RemoveAgent(agent : BaseAgent):
	assert(agent != null, "Agent is null, can't remove it")
	if agent:

		if agent is AIAgent:
			var inst : WorldInstance = agent.get_parent()
			if inst and inst.timers and agent.spawnInfo and agent.spawnInfo.is_persistant:
				Callback.SelfDestructTimer(inst.timers, agent.spawnInfo.respawn_delay, WorldAgent.CreateAgent, [agent.spawnInfo, inst.id])
			if agent.leader != null:
				agent.leader.RemoveFollower(agent)

		PopAgent(agent)
		agents.erase(agent)
		agent.queue_free()

static func HasAgent(inst : WorldInstance, agent : BaseAgent):
	var hasAgent : bool = false
	assert(agent != null and inst != null, "Agent or instance are invalid, could not check if the agent is inside the instance")
	if agent and inst:
		if agent is PlayerAgent:
			hasAgent = inst.players.has(agent)
		elif agent is MonsterAgent:
			hasAgent = inst.mobs.has(agent)
		elif agent is NpcAgent:
			hasAgent = inst.npcs.has(agent)
	return hasAgent

static func PopAgent(agent : BaseAgent):
	assert(agent != null, "Agent is null, can't pop it")
	if agent:
		var inst : WorldInstance = GetInstanceFromAgent(agent)
		if inst:
			Network.NotifyNeighbours(agent, "RemoveEntity", [], false)
			if agent is PlayerAgent:
				inst.players.erase(agent)
				if inst.players.size() == 0:
					inst.QueryProcessMode()
			elif agent is MonsterAgent:
				inst.mobs.erase(agent)
			elif agent is NpcAgent:
				inst.npcs.erase(agent)
			inst.remove_child(agent)

static func PushAgent(agent : BaseAgent, inst : WorldInstance):
	assert(agent != null, "Agent is null, can't push it")
	assert(inst != null, "Instance is null, can't push the agent in it")		
	if agent and inst:
		if not HasAgent(inst, agent):
			if agent is PlayerAgent:
				inst.players.push_back(agent)
				inst.RefreshProcessMode()
			elif agent is MonsterAgent:
				inst.mobs.push_back(agent)
			elif agent is NpcAgent:
				inst.npcs.push_back(agent)

			inst.add_child.call_deferred(agent)
	else:
		RemoveAgent(agent)

static func CreateAgent(spawn : SpawnObject, instanceID : int = 0, nickname : String = "") -> BaseAgent:
	var agent : BaseAgent = null
	var data : EntityData = Instantiate.FindEntityReference(spawn.name)
	if not data:
		return null

	var position : Vector2 = WorldNavigation.GetSpawnPosition(spawn.map, spawn, !(data._behaviour & AICommons.Behaviour.IMMOBILE))
	if Vector2i(position) == Vector2i.ZERO:
		return null

	agent = Instantiate.CreateAgent(spawn, data, spawn.nick if nickname.length() == 0 else nickname)
	if not agent:
		return null

	AddAgent(agent)
	Launcher.World.Warp(agent, spawn.map, position, instanceID)
	return agent

static func _post_launch():
	defaultSpawnLocation.map				= Launcher.World.GetMap(LauncherCommons.DefaultStartMap)
	defaultSpawnLocation.spawn_position		= LauncherCommons.DefaultStartPos
	defaultSpawnLocation.type				= "Player"
	defaultSpawnLocation.name				= "Default"
