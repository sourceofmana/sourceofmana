extends Node
class_name WorldAgent

static var agents : Dictionary = {}

# From Agent getters
static func GetInstanceFromAgent(agent : BaseAgent) -> SubViewport:
	var inst : WorldService.Instance = agent.get_parent()
	Util.Assert(inst != null && inst.is_class("SubViewport"), "Agent's base instance is incorrect, is type: " + inst.get_class() if inst else "null" )
	if inst && inst.is_class("SubViewport"):
		if not WorldAgent.HasAgent(inst, agent):
			inst = null
	return inst

static func GetMapFromAgent(agent : BaseAgent) -> WorldService.Map:
	var map : WorldService.Map = null
	var inst : WorldService.Instance = WorldAgent.GetInstanceFromAgent(agent)
	if inst:
		Util.Assert(inst.map != null, "Agent's base map is incorrect, instance is not referenced inside a map")
		map = inst.map
	return map

static func GetNeighboursFromAgent(checkedAgent : BaseAgent) -> Array[Array]:
	var neighbours : Array[Array] = []
	var instance : WorldService.Instance = WorldAgent.GetInstanceFromAgent(checkedAgent)
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
	Util.Assert(agent != null, "Agent is null, can't add it")
	if agent and not agents.has(agent.get_rid().get_id()):
		agents[agent.get_rid().get_id()] = agent

static func RemoveAgent(agent : BaseAgent):
	Util.Assert(agent != null, "Agent is null, can't remove it")
	if agent:
		if agent.get_parent() and agent.spawnInfo and agent.spawnInfo.is_persistant:
			Util.SelfDestructTimer(agent.get_parent(), agent.spawnInfo.respawn_delay, WorldAgent.CreateAgent.bind(agent.spawnInfo), "RespawnTimer")

		WorldAgent.PopAgent(agent)
		agents.erase(agent)
		agent.queue_free()

static func HasAgent(inst : WorldService.Instance, agent : BaseAgent):
	var hasAgent : bool = false
	Util.Assert(agent != null and inst != null, "Agent or instance are invalid, could not check if the agent is inside the instance")
	if agent and inst:
		if agent is PlayerAgent:
			hasAgent = inst.players.has(agent)
		elif agent is MonsterAgent:
			hasAgent = inst.mobs.has(agent)
		elif agent is NpcAgent:
			hasAgent = inst.npcs.has(agent)
	return hasAgent

static func PopAgent(agent : BaseAgent):
	Util.Assert(agent != null, "Agent is null, can't pop it")
	if agent:
		var inst : WorldService.Instance = WorldAgent.GetInstanceFromAgent(agent)
		Launcher.Network.Server.NotifyInstancePlayers(inst, agent, "RemoveEntity", [], false)
		if inst:
			if agent is PlayerAgent:
				inst.players.erase(agent)
				if inst.players.size() == 0:
					inst.set_process_mode(ProcessMode.PROCESS_MODE_DISABLED)
			elif agent is MonsterAgent:
				inst.mobs.erase(agent)
			elif agent is NpcAgent:
				inst.npcs.erase(agent)
			inst.remove_child.call_deferred(agent)

static func PushAgent(agent : BaseAgent, inst : WorldService.Instance):
	Util.Assert(agent != null, "Agent is null, can't push it")
	Util.Assert(inst != null, "Instance is null, can't push the agent in it")		
	if agent and inst:
		if not WorldAgent.HasAgent(inst, agent):
			if agent is PlayerAgent:
				if inst.players.size() == 0:
					inst.set_process_mode(ProcessMode.PROCESS_MODE_INHERIT)
				inst.players.push_back(agent)
			elif agent is MonsterAgent:
				inst.mobs.push_back(agent)
			elif agent is NpcAgent:
				inst.npcs.push_back(agent)

			inst.add_child.call_deferred(agent)
	else:
		WorldAgent.RemoveAgent(agent)

static func CreateAgent(spawn : SpawnObject, instanceID : int = 0, nickname : String = "") -> BaseAgent:
	var position : Vector2 = WorldNavigation.GetSpawnPosition(spawn.map, spawn)
	if Vector2i(position) == Vector2i.ZERO:
		return null

	var agent : BaseAgent = Instantiate.CreateAgent(spawn.type, spawn.name, nickname)
	agent.spawnInfo = spawn
	agent.position = position

	WorldAgent.AddAgent(agent)
	Launcher.World.Spawn(spawn.map, agent, instanceID)

	return agent
