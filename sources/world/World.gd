extends ServiceBase

# Vars
var areas : Dictionary						= {}

# Getters
func CanWarp(agent : BaseAgent) -> WarpObject:
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map:
		for warp in map.warps:
			if warp and Geometry2D.is_point_in_polygon(agent.get_position(), warp.polygon):
				return warp
	return null

func GetMap(mapName : String) -> WorldMap:
	return areas.get(mapName, null)

# Core functions
func Warp(agent : BaseAgent, newMap : WorldMap, newPos : Vector2i, instanceID : int = 0):
	assert(newMap != null and agent != null, "Warp could not proceed, agent or new map missing")
	if agent and newMap:
		WorldAgent.PopAgent(agent)
		agent.position = agent.exploreOrigin.pos if newMap.HasFlags(WorldMap.Flags.ONLY_SPIRIT) and newPos == Vector2i.ZERO else newPos
		agent.SwitchInputMode(true)
		Spawn(newMap, agent, instanceID)

func Spawn(map : WorldMap, agent : BaseAgent, instanceID : int = 0):
	assert(map != null and instanceID < map.instances.size() and agent != null, "Spawn could not proceed, agent or map missing")
	if map and instanceID < map.instances.size() and agent:
		var inst : WorldInstance = map.instances[instanceID]
		assert(inst != null, "Spawn could not proceed, map instance missing")
		if inst:
			agent.ResetNav()
			if agent.agent:
				agent.agent.set_velocity_forced(Vector2.ZERO)
				agent.agent.set_navigation_map(map.mapRID)
			agent.currentVelocity = Vector2.ZERO
			agent.state = ActorCommons.State.IDLE

			WorldAgent.PushAgent(agent, inst)
			Callback.OneShotCallback(agent.tree_entered, AgentWarped, [map, agent])

func AgentWarped(map : WorldMap, agent : BaseAgent):
	if agent == null:
		return

	if agent is PlayerAgent:
		if agent.rpcRID == NetworkCommons.RidUnknown:
			return

		if map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
			if not agent.stat.IsMorph():
				agent.Morph(false, agent.stat.spirit)
		else:
			if agent.stat.IsMorph():
				agent.Morph(false, agent.stat.shape)

		Network.WarpPlayer(map.name, agent.rpcRID)
		for neighbours in WorldAgent.GetNeighboursFromAgent(agent):
			for neighbour in neighbours:
				var neighbourRID : int = neighbour.get_rid().get_id()
				Network.AddEntity(neighbourRID, neighbour.GetEntityType(), neighbour.stat.shape, neighbour.stat.spirit, neighbour.stat.currentShape, neighbour.nick, neighbour.velocity, neighbour.position, neighbour.currentOrientation, neighbour.state, neighbour.currentSkillID, agent.rpcRID)
				Network.UpdatePublicStats(neighbourRID, neighbour.stat.level, neighbour.stat.health, neighbour.stat.hairstyle, neighbour.stat.haircolor, neighbour.stat.gender, neighbour.stat.race, neighbour.stat.skintone, neighbour.stat.currentShape, agent.rpcRID)
				if neighbour.inventory:
					Network.RefreshEquipments(neighbourRID, neighbour.inventory.ExportEquipment(), agent.rpcRID)

		Network.RefreshProgress(agent.progress.skills, agent.progress.quests, agent.progress.bestiary, agent.rpcRID)
	Network.NotifyNeighbours(agent, "AddEntity", [agent.GetEntityType(), agent.stat.shape, agent.stat.spirit, agent.stat.currentShape, agent.nick, agent.velocity, agent.position, agent.currentOrientation, agent.state, agent.currentSkillID], false)
	if agent.inventory:
		Network.NotifyNeighbours(agent, "RefreshEquipments", [agent.inventory.ExportEquipment()], false)

# Generic
func BackupPlayers():
	for area in areas.values():
		for inst in area.instances:
			for player in inst.players:
				Launcher.SQL.RefreshCharacter(player)

func _post_launch():
	for mapName in DB.MapsDB:
		areas[mapName] = WorldMap.Create(mapName)
	WorldAgent._post_launch()

	isInitialized = true

func Destroy():
	for area in areas.values():
		for inst in area.instances:
			for player in inst.players:
				WorldAgent.RemoveAgent(player)
			for mob in inst.mobs:
				WorldAgent.RemoveAgent(mob)
			for npc in inst.npcs:
				WorldAgent.RemoveAgent(npc)
			Launcher.Root.remove_child(inst)
			inst.queue_free()
