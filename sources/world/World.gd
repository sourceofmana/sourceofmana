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

# Core functions
func Warp(agent : BaseAgent, newMap : WorldMap, newPos : Vector2i, instanceID : int = 0):
	assert(newMap != null and agent != null, "Warp could not proceed, agent or new map missing")
	if agent and newMap:
		WorldAgent.PopAgent(agent)
		if not agent.isRelativeMode:
			agent.SwitchInputMode(true)
		agent.position = agent.exploreOrigin.pos if newMap.HasFlags(WorldMap.Flags.ONLY_SPIRIT) and newPos == Vector2i.ZERO else newPos
		Spawn(newMap, agent, instanceID)

func Spawn(map : WorldMap, agent : BaseAgent, instanceID : int = 0):
	assert(map != null and instanceID < map.instances.size() and agent != null, "Spawn could not proceed, agent or map missing")
	if map and instanceID < map.instances.size() and agent:
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
		else:
			if agent.stat.IsMorph():
				agent.Morph(false, agent.stat.shape)

		Network.WarpPlayer(map.id, agent.position, agent.peerID)
		var instance : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
		if instance:
			for neighbour in instance.players:
				var neighbourRID : int = neighbour.get_rid().get_id()
				Network.Bulk("AddPlayer", [
					neighbourRID, neighbour.GetActorType(), neighbour.stat.shape,
					neighbour.stat.spirit, neighbour.stat.currentShape, neighbour.nick,
					neighbour.velocity, neighbour.position, neighbour.currentOrientation,
					neighbour.state, neighbour.currentSkillID,
					neighbour.stat.level, neighbour.stat.health,
					neighbour.stat.hairstyle, neighbour.stat.haircolor,
					neighbour.stat.gender, neighbour.stat.race, neighbour.stat.skintone,
					neighbour.inventory.ExportEquipment() if neighbour.inventory else {}
				], agent.peerID)
			for neighbour in instance.npcs:
				var neighbourRID : int = neighbour.get_rid().get_id()
				Network.Bulk("AddEntity", [
					neighbourRID, neighbour.GetActorType(),
					neighbour.stat.currentShape, neighbour.nick,
					neighbour.velocity, neighbour.position, neighbour.currentOrientation,
					neighbour.state, neighbour.currentSkillID,
				], agent.peerID)
			for neighbour in instance.mobs:
				var neighbourRID : int = neighbour.get_rid().get_id()
				Network.Bulk("AddEntity", [
					neighbourRID, neighbour.GetActorType(),
					neighbour.stat.currentShape, neighbour.nick,
					neighbour.velocity, neighbour.position, neighbour.currentOrientation,
					neighbour.state, neighbour.currentSkillID,
				], agent.peerID)

		Network.NotifyNeighbours(agent, "AddPlayer", [
			agent.GetActorType(),
			agent.stat.shape, agent.stat.spirit, agent.stat.currentShape, agent.nick,
			agent.velocity, agent.position, agent.currentOrientation,
			agent.state, agent.currentSkillID,
			agent.stat.level, agent.stat.health,
			agent.stat.hairstyle, agent.stat.haircolor,
			agent.stat.gender, agent.stat.race, agent.stat.skintone,
			agent.inventory.ExportEquipment() if agent.inventory else {}
		], false)
	else:
		Network.NotifyNeighbours(agent, "AddEntity", [
			agent.GetActorType(), agent.stat.currentShape, agent.nick,
			agent.velocity, agent.position, agent.currentOrientation,
			agent.state, agent.currentSkillID
		], false)

# Generic
func BackupPlayers():
	for areaIdx in areas:
		var area = areas[areaIdx]
		for inst in area.instances:
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
