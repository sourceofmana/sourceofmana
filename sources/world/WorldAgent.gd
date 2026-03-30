extends Node
class_name WorldAgent

static var agents : Dictionary[int, BaseAgent]		= {}
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

# Basic Agent container handling
static func GetAgent(agentRID : int) -> BaseAgent:
	var agent : BaseAgent = null
	if agents.has(agentRID):
		agent = agents.get(agentRID)
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
		agents.erase(agent.get_rid().get_id())
		agent.queue_free()

static func PopAgent(agent : BaseAgent):
	assert(agent != null, "Agent is null, can't pop it")
	if agent:
		var inst : WorldInstance = GetInstanceFromAgent(agent)
		if inst:
			agent.set_physics_process(false)
			if agent is PlayerAgent:
				inst.players.erase(agent)
				agent.visibleAgents.clear()
				if inst.players.is_empty():
					if inst.id != 0 and inst.map:
						inst.map.DestroyInstance.call_deferred(inst.id)
					else:
						inst.QueryProcessMode()
				else:
					var agentRID : int = agent.get_rid().get_id()
					for neighbour in inst.players:
						if neighbour and neighbour.visibleAgents.has(agentRID):
							Network.Bulk("RemoveEntity", [agentRID], neighbour.peerID)
							neighbour.visibleAgents.erase(agentRID)
			elif agent is MonsterAgent:
				inst.mobs.erase(agent)
			elif agent is NpcAgent:
				inst.npcs.erase(agent)
			inst.remove_child(agent)

static func PushAgent(agent : BaseAgent, inst : WorldInstance):
	assert(agent != null, "Agent is null, can't push it")
	assert(inst != null, "Instance is null, can't push the agent in it")		
	if agent and inst:
		agent.set_physics_process(true)
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
	var data : EntityData = DB.EntitiesDB.get(spawn.id, null)
	if not data:
		return null

	var inst : WorldInstance = spawn.map.instances.get(instanceID, null)
	if not inst:
		return null

	var position : Vector2i = WorldNavigation.GetSpawnPosition(inst, spawn)
	if position == Vector2i.ZERO:
		return null

	agent = Instantiate.CreateAgent(spawn, data, spawn.nick if nickname.length() == 0 else nickname)
	if not agent:
		return null

	AddAgent(agent)
	Launcher.World.Warp(agent, spawn.map, position, instanceID)
	return agent

static func _post_launch():
	defaultSpawnLocation.map				= Launcher.World.GetMap(LauncherCommons.DefaultStartMapID)
	defaultSpawnLocation.spawn_position		= LauncherCommons.DefaultStartPos
	defaultSpawnLocation.type				= "Player"
	defaultSpawnLocation.id					= DB.PlayerHash
