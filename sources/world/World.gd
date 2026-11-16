extends ServiceBase
class_name WorldService

# Vars
var areas : Dictionary[int, WorldMap]				= {}
var commands : WorldCommands						= WorldCommands.new()
var canary : ShutdownCanary							= ShutdownCanary.new()
var deploy : ServerDeploy							= ServerDeploy.new()

# Getters
func GetMap(mapID : int) -> WorldMap:
	return areas.get(mapID, null)

func GetGlobalPlayer(nickname : String) -> PlayerAgent:
	for areaIdx in areas:
		var area = areas[areaIdx]
		for inst in area.instances.values():
			for player in inst.players:
				if player.nick == nickname:
					return player
	return null

func GetGlobalNpc(nickname : String) -> NpcAgent:
	for areaIdx in areas:
		var area = areas[areaIdx]
		for inst in area.instances.values():
			for npc in inst.npcs:
				if npc.nick == nickname:
					return npc
	return null

# Helper
func GetPreloadMethod(agent : BaseAgent) -> StringName:
	return &"PreloadPlayer" if agent is PlayerAgent else &"PreloadEntity"

func GetPreloadArgs(agent : BaseAgent, agentRID : int) -> Array:
	if agent is PlayerAgent:
		return [
			agentRID, agent.stat.spirit, agent.stat.currentShape, agent.nick,
			agent.stat.level, agent.stat.health,
			agent.stat.hairstyle, agent.stat.haircolor,
			agent.stat.gender, agent.stat.race, agent.stat.skintone,
			agent.inventory.ExportEquipment() if agent.inventory else {}
		]
	return [agentRID, agent.GetActorType(), agent.stat.currentShape, agent.nick, agent.defaultState]

func BulkPreload(agent : BaseAgent, agentRID : int, peerID : int):
	Network.Bulk(GetPreloadMethod(agent), GetPreloadArgs(agent, agentRID), peerID)

func AppendPreload(preloads : Dictionary, agent : BaseAgent):
	preloads[GetPreloadMethod(agent)].append(GetPreloadArgs(agent, agent.get_rid().get_id()))

func SendArrival(agent : PlayerAgent, map : WorldMap, instance : WorldInstance):
	Network.WarpPlayer(map.id, agent.position, agent.peerID)
	if not instance:
		return

	var preloads : Dictionary = { &"PreloadPlayer": [], &"PreloadEntity": [] }
	for neighbour in instance.players:
		if neighbour:
			AppendPreload(preloads, neighbour)
	for neighbour in instance.npcs:
		if neighbour and neighbour.isVisible:
			AppendPreload(preloads, neighbour)
	for neighbour in instance.mobs:
		if neighbour:
			AppendPreload(preloads, neighbour)
	for methodName : StringName in preloads:
		if not preloads[methodName].is_empty():
			Network.BulkCall(methodName, preloads[methodName], agent.peerID)

	Network.FullUpdateEntity(
		agent.get_rid().get_id(), agent.velocity, agent.position, agent.currentOrientation,
		agent.state, agent.currentSkillID, agent.stat.isRunning, NetworkCommons.FrameID(), agent.peerID
	)

	agent.visibleAgents.clear()
	agent.lastCheckedPosition = agent.position
	agent.UpdateVisibility()

# Core functions
func Warp(agent : BaseAgent, newMap : WorldMap, newPos : Vector2i, direction : ActorCommons.Direction, instanceID : int = 0):
	assert(newMap != null and agent != null, "Warp could not proceed, agent or new map missing")
	if agent and newMap:
		if agent is PlayerAgent:
			var currentMap : WorldMap = WorldAgent.GetMapFromAgent(agent)
			if currentMap and currentMap.HasFlags(WorldMap.Flags.ONLY_SPIRIT) and not newMap.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
				agent.Morph(false, agent.stat.shape)

		# Force reset velocity to prevent any input residue due to the map transition
		agent._velocity_computed(Vector2.ZERO)
		agent.currentVelocity = Vector2.ZERO
		agent.velocity = Vector2.ZERO
		if agent is PlayerAgent:
			agent.isWarping = true
		WorldAgent.PopAgent(agent)
		if not agent.isRelativeMode:
			agent.SwitchInputMode(true)

		agent.position = newPos
		if direction != ActorCommons.Direction.UNKNOWN:
			agent.currentOrientation = ActorCommons.GetDirectionFromEnum(direction)

		Spawn(newMap, agent, instanceID)

func Spawn(map : WorldMap, agent : BaseAgent, instanceID : int = 0):
	assert(map != null and map.instances.has(instanceID) and agent != null, "Spawn could not proceed, agent or map missing")
	if map and map.instances.has(instanceID) and agent:
		var inst : WorldInstance = map.instances[instanceID]
		assert(inst != null, "Spawn could not proceed, map instance missing")
		if inst:
			if agent.is_node_ready():
				AgentCreated(agent, map.mapRID)
			else:
				Callback.OneShotCallback(agent.ready, AgentCreated, [agent, map.mapRID])
			Callback.OneShotCallback(agent.tree_entered, AgentWarped, [map, agent])
			WorldAgent.PushAgent(agent, inst)

func ClearWarpFlag(agent : PlayerAgent):
	if agent and agent.is_inside_tree():
		await agent.get_tree().physics_frame
		agent.isWarping = false
		agent.warp_confirmed.emit()

func AgentCreated(agent : BaseAgent, mapRID : RID):
	if agent and agent.agent:
		agent.agent.set_navigation_map(mapRID)

func AgentWarped(map : WorldMap, agent : BaseAgent):
	if agent == null:
		return

	var instance : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
	if agent is PlayerAgent:
		if agent.peerID == NetworkCommons.PeerUnknownID:
			return

		if map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
			if not agent.stat.IsMorph():
				agent.Morph(false, agent.stat.spirit)

		SendArrival(agent, map, instance)
		ClearWarpFlag(agent)

	if instance:
		var agentRID : int = agent.get_rid().get_id()
		for player in instance.players:
			if player and player != agent and player.peerID != NetworkCommons.PeerUnknownID:
				BulkPreload(agent, agentRID, player.peerID)

# Generic
func BackupPlayers():
	for area : WorldMap in areas.values():
		for inst : WorldInstance in area.instances.values():
			for player : PlayerAgent in inst.players:
				Launcher.SQL.RefreshCharacter(player)


func _post_launch():
	if not DB.isInitialized:
		if not Launcher.dbInitialized.is_connected(_init_world):
			Launcher.dbInitialized.connect(_init_world, CONNECT_ONE_SHOT)
		return
	_init_world()

func _init_world():
	for mapID in DB.MapsDB:
		areas[mapID] = WorldMap.Create(mapID)
	WorldAgent._post_launch()
	canary.Start()
	isInitialized = true

func Destroy():
	for areaIdx in areas:
		areas[areaIdx].Destroy()
	areas.clear()
