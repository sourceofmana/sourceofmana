extends Node
class_name WorldAgent

static var agents : Dictionary = {}

# From Agent getters
static func GetInstanceFromAgent(agent : BaseAgent) -> SubViewport:
	var inst = agent.get_parent()
	Util.Assert(inst != null && inst.is_class("SubViewport"), "Agent's base instance is incorrect, is type: " + inst.get_class() if inst else "null" )
	if inst && inst.is_class("SubViewport"):
		if not WorldAgent.HasAgent(inst, agent):
			inst = null
	return inst

static func GetMapFromAgent(agent : BaseAgent) -> World.Map:
	var map : World.Map = null
	var inst : World.Instance = WorldAgent.GetInstanceFromAgent(agent)
	if inst:
		Util.Assert(inst.map != null, "Agent's base map is incorrect, instance is not referenced inside a map")
		map = inst.map
	return map

static func GetAgentsFromAgent(checkedAgent : BaseAgent) -> Array[Array]:
	var list : Array[Array] = []
	var instance : World.Instance = WorldAgent.GetInstanceFromAgent(checkedAgent)
	if instance:
		list.append(instance.npcs)
		list.append(instance.mobs)
		list.append(instance.players)
	return list

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
		if agent.spawnInfo and agent.spawnInfo.is_persistant:
			var timer = Timer.new()
			timer.set_name("SpawnTimer")
			timer.set_one_shot(true)
			Launcher.add_child(timer)
			Util.StartTimer(timer, 1, WorldAgent.CreateAgent.bind(agent.spawnInfo))

		WorldAgent.PopAgent(agent)
		agents.erase(agent)
		agent.queue_free()

static func HasAgent(inst : World.Instance, agent : BaseAgent):
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
		var inst : World.Instance = WorldAgent.GetInstanceFromAgent(agent)
		Launcher.Network.Server.NotifyInstancePlayers(inst, agent, "RemoveEntity", [], false)
		if inst:
			if agent is PlayerAgent:
				inst.players.erase(agent)
			elif agent is MonsterAgent:
				inst.mobs.erase(agent)
			elif agent is NpcAgent:
				inst.npcs.erase(agent)
			inst.call_deferred("remove_child", agent)

static func PushAgent(agent : BaseAgent, inst : World.Instance):
	Util.Assert(agent != null, "Agent is null, can't push it")
	Util.Assert(inst != null, "Instance is null, can't push the agent in it")		
	if agent and inst:
		if not WorldAgent.HasAgent(inst, agent):
			if agent is PlayerAgent:
				inst.players.push_back(agent)
			elif agent is MonsterAgent:
				inst.mobs.push_back(agent)
			elif agent is NpcAgent:
				inst.npcs.push_back(agent)

			inst.call_deferred("add_child", agent)
			Launcher.Network.Server.NotifyInstancePlayers(inst, agent, "AddEntity", [agent.agentType, agent.agentID, agent.agentName, agent.position, agent.currentState], false)
	else:
		WorldAgent.RemoveAgent(agent)

static func CreateAgent(spawn : SpawnObject, instanceID : int = 0, agent : BaseAgent = null, nickname : String = ""):
	if not agent:
		agent = Instantiate.CreateAgent(spawn.type, spawn.name, nickname)
	Util.Assert(agent != null, "Agent %s (type: %s) could not be created" % [spawn.name, spawn.type])
	if agent:
		agent.spawnInfo = spawn
		agent.position = WorldNavigation.GetSpawnPosition(spawn.map, spawn)
		if Vector2i(agent.position) != Vector2i.ZERO:
			WorldAgent.AddAgent(agent)
			Launcher.World.Spawn(spawn.map, agent, instanceID)
		else:
			agent.queue_free()
			agent = null
