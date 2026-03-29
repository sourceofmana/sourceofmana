extends BaseAgent
class_name PlayerAgent

# Player-specific variables
var peerID : int						= NetworkCommons.PeerUnknownID
var lastStat : ActorStats				= ActorStats.new()
var respawnDestination : Destination	= null
var exploreOrigin : Destination			= null
var ownScript : NpcScript				= null

# Regen
var regenTimer : Timer					= null
var statsUpdatePending : bool			= false

# Visible surrounding actors
var visibleAgents : Dictionary[int, bool]= {}
var lastCheckedPosition : Vector2		= Vector2.ZERO
var visibilityTimer : Timer				= null
var visibilityHalfSize : Vector2		= Vector2(NetworkCommons.MaxVisibilityHalfWidth, NetworkCommons.MaxVisibilityHalfHeight)

#
static func GetActorType() -> ActorCommons.Type: return ActorCommons.Type.PLAYER

#
static func GetDestinationFromData(charData : Dictionary, destID : String, posXID : String, posYID : String) -> Destination:
	var mapID = charData.get(destID, DB.UnknownHash)
	var mapPosX = charData.get(posXID, 0)
	var mapPosY = charData.get(posYID, 0)
	var map : WorldMap = Launcher.World.GetMap(mapID) if mapID and mapID != DB.UnknownHash else null
	var pos : Vector2 = Vector2(mapPosX if mapPosX else 0, mapPosY if mapPosY else 0)
	return Destination.new(map.id if map else DB.UnknownHash, pos)

static func GetSpawnFromData(charData : Dictionary) -> SpawnObject:
	var destination : Destination = GetDestinationFromData(charData, "pos_map", "pos_x", "pos_y")
	if destination.mapID != DB.UnknownHash:
		var spawnLocation : SpawnObject = SpawnObject.new()
		spawnLocation.map				= Launcher.World.GetMap(destination.mapID)
		spawnLocation.spawn_position	= destination.pos
		spawnLocation.type				= "Player"
		spawnLocation.id				= DB.PlayerHash
		return spawnLocation
	return WorldAgent.defaultSpawnLocation

static func GetRespawnFromData(charData : Dictionary) -> Destination:
	var destination : Destination = GetDestinationFromData(charData, "respawn_map", "respawn_x", "respawn_y")
	return destination if destination.mapID != DB.UnknownHash else Destination.new(WorldAgent.defaultSpawnLocation.map.id, WorldAgent.defaultSpawnLocation.spawn_position)

static func GetExploreFromData(charData : Dictionary) -> Destination:
	return GetDestinationFromData(charData, "explore_map", "explore_x", "explore_y")

func SetCharacterInfo(charData : Dictionary, charID : int):
	# Stats
	stat.SetStats(charData)
	# Inventory
	var inventoryData : Array[Dictionary] = Launcher.SQL.GetStorage(charID, 0)
	inventory.ImportInventory(inventoryData)
	# Equiped items
	var equipmentData : Dictionary = Launcher.SQL.GetEquipment(charID)
	inventory.ImportEquipment(equipmentData)
	# Respawn
	respawnDestination = GetRespawnFromData(charData)
	# Explore
	exploreOrigin = GetExploreFromData(charData)
	# Progress
	progress.ImportProgress(charID)

#
func UpdateLastStats():
	if peerID == NetworkCommons.PeerUnknownID:
		return

	if lastStat.level != stat.level or \
	lastStat.health != stat.health or \
	lastStat.hairstyle != stat.hairstyle or \
	lastStat.haircolor != stat.haircolor or \
	lastStat.gender != stat.gender or \
	lastStat.race != stat.race or \
	lastStat.skintone != stat.skintone or \
	lastStat.currentShape != stat.currentShape:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(self)
		if inst:
			Network.NotifyInstance(inst, "UpdatePublicStats", [get_rid().get_id(), stat.level, stat.health, stat.current.maxHealth, stat.hairstyle, stat.haircolor, stat.gender, stat.race, stat.skintone, stat.currentShape])
		if lastStat.level != 0 and lastStat.level < stat.level:
			Network.NotifyNeighbours(self, "LevelUp", [])
		lastStat.level				= stat.level
		lastStat.health				= stat.health
		lastStat.hairstyle			= stat.hairstyle
		lastStat.haircolor			= stat.haircolor
		lastStat.gender				= stat.gender
		lastStat.race				= stat.race
		lastStat.skintone			= stat.skintone
		lastStat.currentShape		= stat.currentShape

	if lastStat.experience != stat.experience or \
	lastStat.gp != stat.gp or \
	lastStat.mana != stat.mana or \
	lastStat.stamina != stat.stamina or \
	lastStat.karma != stat.karma or \
	lastStat.weight != stat.weight or \
	lastStat.shape != stat.shape or \
	lastStat.spirit != stat.spirit:
		Network.UpdatePrivateStats(stat.experience, stat.gp, stat.mana, stat.stamina, stat.karma, stat.weight, stat.shape, stat.spirit, peerID)
		lastStat.level				= stat.level
		lastStat.experience			= stat.experience
		lastStat.gp					= stat.gp
		lastStat.health				= stat.health
		lastStat.mana				= stat.mana
		lastStat.stamina			= stat.stamina
		lastStat.karma				= stat.karma
		lastStat.weight				= stat.weight
		lastStat.shape				= stat.shape
		lastStat.spirit				= stat.spirit

	if lastStat.strength != stat.strength or \
	lastStat.vitality != stat.vitality or \
	lastStat.agility != stat.agility or \
	lastStat.endurance != stat.endurance or \
	lastStat.concentration != stat.concentration:
		Network.UpdateAttributes(stat.strength, stat.vitality, stat.agility, stat.endurance, stat.concentration, peerID)
		lastStat.strength			= stat.strength
		lastStat.vitality			= stat.vitality
		lastStat.agility			= stat.agility
		lastStat.endurance			= stat.endurance
		lastStat.concentration		= stat.concentration

func Morph(notifyMorphing : bool, morphID : int = DB.UnknownHash):
	if morphID == DB.UnknownHash:
		morphID = GetNextShapeID()

	var morphData : EntityData = DB.EntitiesDB.get(morphID, null)
	if morphData:
		stat.Morph(morphData)
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(self)
		if inst:
			Network.NotifyInstance(inst, "Morphed", [get_rid().get_id(), morphID, notifyMorphing])


# Running
func SetRunning(enable : bool):
	if stat.isRunning != enable:
		if not enable or (stat.stamina > 0 and state == ActorCommons.State.WALK):
			stat.isRunning = enable
			RefreshWalkSpeed()
			requireFullUpdate = true

#
func OnRegenTick():
	UpdateDeltas(ActorCommons.RegenTickInterval)

func RequestStatsUpdate():
	if not statsUpdatePending:
		statsUpdatePending = true
		FlushStatsUpdate.call_deferred()

func FlushStatsUpdate():
	statsUpdatePending = false
	UpdateLastStats()

func CheckVisibility(neighbour : BaseAgent):
	if not neighbour:
		return
	if NetworkCommons.IsAlwaysVisible(neighbour) or NetworkCommons.IsVisible(position, neighbour.position, visibilityHalfSize):
		var agentRID : int = neighbour.get_rid().get_id()
		if not visibleAgents.has(agentRID):
			Network.Bulk("FullUpdateEntity", [agentRID, neighbour.velocity, neighbour.position, neighbour.currentOrientation, neighbour.state, neighbour.currentSkillID, neighbour.stat.isRunning], peerID)
		visibleAgents[agentRID] = true

func UpdateVisibility():
	if peerID == NetworkCommons.PeerUnknownID:
		return
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(self)
	if not inst:
		return

	# Pre-set every previously visible agents to false
	for agentRID in visibleAgents:
		visibleAgents[agentRID] = false

	# Set every visible agents to true
	for neighbour in inst.players:
		if neighbour != self:
			CheckVisibility(neighbour)
	for neighbour in inst.npcs:
		CheckVisibility(neighbour)
	for neighbour in inst.mobs:
		CheckVisibility(neighbour)

	# Remove any previously visible agents that just disapeared
	for agentRID in visibleAgents:
		if not visibleAgents[agentRID]:
			Network.Bulk("RemoveEntity", [agentRID], peerID)
			visibleAgents.erase(agentRID)

func NotifyPosition():
	super.NotifyPosition()
	if position.distance_squared_to(lastCheckedPosition) >= ActorCommons.VisibilityCheckDistSqrd:
		lastCheckedPosition = position
		UpdateVisibility()

func _ready():
	super._ready()

	regenTimer = Timer.new()
	regenTimer.set_name("RegenTimer")
	regenTimer.set_one_shot(false)
	regenTimer.set_wait_time(ActorCommons.RegenTickInterval)
	regenTimer.autostart = true
	regenTimer.timeout.connect(OnRegenTick)
	add_child.call_deferred(regenTimer)

	visibilityTimer = Timer.new()
	visibilityTimer.set_name("VisibilityTimer")
	visibilityTimer.set_one_shot(false)
	visibilityTimer.set_wait_time(ActorCommons.VisibilityCheckTimeInternal)
	visibilityTimer.autostart = true
	visibilityTimer.timeout.connect(UpdateVisibility)
	add_child.call_deferred(visibilityTimer)

	stat.entity_stats_updated.connect(RequestStatsUpdate)
	stat.vital_stats_updated.connect(RequestStatsUpdate)

func _exit_tree():
	ClearScript()
	super._exit_tree()

#
func Respawn():
	if Revive():
		WarpTo(respawnDestination)

func Explore():
	if ActorCommons.IsAlive(self):
		var map : WorldMap = WorldAgent.GetMapFromAgent(self)
		if map and map.HasFlags(WorldMap.Flags.ONLY_SPIRIT):
			if stat.IsSailing():
				exploreOrigin.mapID = map.id
				exploreOrigin.pos = position
				WarpTo(ActorCommons.SailingDestination)

func WarpTo(dest : Destination):
	var nextMap : WorldMap = Launcher.World.GetMap(dest.mapID)
	if nextMap:
		Launcher.World.Warp(self, nextMap, dest.pos, dest.instance)

func Killed():
	super.Killed()
	if ownScript:
		ClearScript()
		NpcCommons.ToggleContext(self, false)

func UpdateDeltas(delta : float):
	if ActorCommons.IsRunning(self):
		stat.deltaStamina -= ActorCommons.RunningStaminaCostPerSecond * delta
		if (stat.stamina + stat.deltaStamina) <= 0.0:
			SetRunning(false)
	super.UpdateDeltas(delta)

#
func AddScript(npc : NpcAgent):
	if npc and npc.playerScriptPreset:
		ownScript = npc.playerScriptPreset.new(npc, self)

func ClearScript():
	if ownScript:
		ownScript.OnQuit()
		ownScript = null
