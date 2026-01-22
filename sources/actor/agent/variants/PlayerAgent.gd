extends BaseAgent
class_name PlayerAgent

#
var peerID : int						= NetworkCommons.PeerUnknownID
var lastStat : ActorStats				= ActorStats.new()
var respawnDestination : Destination	= null
var exploreOrigin : Destination			= null
var ownScript : NpcScript				= null

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
		Network.NotifyNeighbours(self, "UpdatePublicStats", [stat.level, stat.health, stat.hairstyle, stat.haircolor, stat.gender, stat.race, stat.skintone, stat.currentShape])
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
		Network.NotifyNeighbours(self, "Morphed", [morphID, notifyMorphing])

#
func _physics_process(delta):
	super._physics_process(delta)
	UpdateLastStats()

func _ready():
	regenTimer = Timer.new()
	regenTimer.set_name("RegenTimer")
	Callback.OneShotCallback(regenTimer.tree_entered, Callback.ResetTimer, [regenTimer, ActorCommons.RegenDelay, stat.Regen])
	add_child.call_deferred(regenTimer)
	super._ready()

func _exit_tree():
	ClearScript()
	super._exit_tree()

#
func Respawn():
	if not ActorCommons.IsAlive(self):
		stat.health  = int(stat.current.maxHealth / 2.0)
		state = ActorCommons.State.IDLE
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

#
func AddScript(npc : NpcAgent):
	if npc and npc.playerScriptPreset:
		ownScript = npc.playerScriptPreset.new(npc, self)

func ClearScript():
	if ownScript:
		ownScript.OnQuit()
		ownScript = null
