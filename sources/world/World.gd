extends ServiceBase

# Vars
var areas : Dictionary[int, WorldMap]				= {}
var commands : WorldCommands						= WorldCommands.new()

# Getters
func CanWarp(agent : BaseAgent) -> WarpObject:
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		for warp in map.warps:
			if warp and Geometry2D.is_point_in_polygon(agent.get_position(), warp.polygon):
				return warp
	return null

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

# Helper
func BulkPreload(agent : BaseAgent, agentRID : int, peerID : int):
	if agent is PlayerAgent:
		Network.Bulk("PreloadPlayer", [
			agentRID, agent.stat.spirit, agent.stat.currentShape, agent.nick,
			agent.stat.level, agent.stat.health,
			agent.stat.hairstyle, agent.stat.haircolor,
			agent.stat.gender, agent.stat.race, agent.stat.skintone,
			agent.inventory.ExportEquipment() if agent.inventory else {}
		], peerID)
	else:
		Network.Bulk("PreloadEntity", [
			agentRID, agent.GetActorType(), agent.stat.currentShape, agent.nick
		], peerID)

# Core functions
func Warp(agent : BaseAgent, newMap : WorldMap, newPos : Vector2i, instanceID : int = 0):
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
		WorldAgent.PopAgent(agent)
		if not agent.isRelativeMode:
			agent.SwitchInputMode(true)
		agent.position = agent.exploreOrigin.pos if newMap.HasFlags(WorldMap.Flags.ONLY_SPIRIT) and newPos == Vector2i.ZERO else newPos
		Spawn(newMap, agent, instanceID)

func Spawn(map : WorldMap, agent : BaseAgent, instanceID : int = 0):
	assert(map != null and map.instances.has(instanceID) and agent != null, "Spawn could not proceed, agent or map missing")
	if map and map.instances.has(instanceID) and agent:
		var inst : WorldInstance = map.instances[instanceID]
		assert(inst != null, "Spawn could not proceed, map instance missing")
		if inst:
			if agent.agent:
				agent.agent.set_navigation_map(map.mapRID)
			Callback.OneShotCallback(agent.tree_entered, AgentWarped, [map, agent])
			WorldAgent.PushAgent(agent, inst)

func AgentWarped(map : WorldMap, agent : BaseAgent):
	if agent == null:
		return

	if agent is PlayerAgent:
		if agent.peerID == NetworkCommons.PeerUnknownID:
			return

		if map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
			if not agent.stat.IsMorph():
				agent.Morph(false, agent.stat.spirit)

		Network.WarpPlayer(map.id, agent.position, agent.peerID)
		agent.visibleAgents.clear()
		var instance : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
		if instance:
			var agentRID : int = agent.get_rid().get_id()
			for neighbour in instance.players:
				if not neighbour:
					continue
				var neighbourRID : int = neighbour.get_rid().get_id()
				BulkPreload(neighbour, neighbourRID, agent.peerID)
			for neighbour in instance.npcs:
				if not neighbour:
					continue
				var neighbourRID : int = neighbour.get_rid().get_id()
				BulkPreload(neighbour, neighbourRID, agent.peerID)
			for neighbour in instance.mobs:
				if not neighbour:
					continue
				var neighbourRID : int = neighbour.get_rid().get_id()
				BulkPreload(neighbour, neighbourRID, agent.peerID)

			# Spawn self
			Network.Bulk("FullUpdateEntity", [
				agentRID, agent.velocity, agent.position, agent.currentOrientation,
				agent.state, agent.currentSkillID, agent.stat.isRunning
			], agent.peerID)

			# Notify existing players about the new arrival
			for player in instance.players:
				if not player or player == agent or player.peerID == NetworkCommons.PeerUnknownID:
					continue
				BulkPreload(agent, agentRID, player.peerID)
	else:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
		var agentRID : int = agent.get_rid().get_id()
		if inst:
			for player in inst.players:
				if not player or player.peerID == NetworkCommons.PeerUnknownID:
					continue
				BulkPreload(agent, agentRID, player.peerID)

# Generic
func BackupPlayers():
	for areaIdx in areas:
		var area = areas[areaIdx]
		for inst in area.instances.values():
			for player in inst.players:
				Launcher.SQL.RefreshCharacter(player)

func _post_launch():
	for mapID in DB.MapsDB:
		areas[mapID] = WorldMap.Create(mapID)
	WorldAgent._post_launch()

	isInitialized = true

func Destroy():
	for areaIdx in areas:
		areas[areaIdx].Destroy()
	areas.clear()
