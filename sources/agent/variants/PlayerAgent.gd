extends BaseAgent
class_name PlayerAgent

#
var lastStat : EntityStats				= EntityStats.new()

#
static func GetEntityType() -> EntityCommons.Type: return EntityCommons.Type.PLAYER

#
func UpdateLastStats():
	var peerID : int = Launcher.Network.Server.GetRid(self)
	if peerID == NetworkCommons.RidUnknown:
		return

	if lastStat.level != stat.level or \
	lastStat.experience != stat.experience:
		Launcher.Network.UpdatePlayerVars(stat.level, stat.experience, peerID)
		lastStat.level				= stat.level
		lastStat.experience			= stat.experience

	if lastStat.health != stat.health or \
	lastStat.mana != stat.mana or \
	lastStat.stamina != stat.stamina or \
	lastStat.weight != stat.weight or \
	lastStat.morphed != stat.morphed:
		Launcher.Network.UpdateActiveStats(stat.health, stat.mana, stat.stamina, stat.weight, stat.morphed, peerID)
		lastStat.health				= stat.health
		lastStat.mana				= stat.mana
		lastStat.stamina			= stat.stamina
		lastStat.weight				= stat.weight
		lastStat.morphed			= stat.morphed

	if lastStat.strength != stat.strength or \
	lastStat.vitality != stat.vitality or \
	lastStat.agility != stat.agility or \
	lastStat.endurance != stat.endurance or \
	lastStat.concentration != stat.concentration:
		Launcher.Network.UpdatePersonalStats(stat.strength, stat.vitality, stat.agility, stat.endurance, stat.concentration, peerID)
		lastStat.strength			= stat.strength
		lastStat.vitality			= stat.vitality
		lastStat.agility			= stat.agility
		lastStat.endurance			= stat.endurance
		lastStat.concentration		= stat.concentration

func Morph(notifyMorphing : bool):
	if stat.spiritShape.length() == 0:
		return

	var map : Object = WorldAgent.GetMapFromAgent(self)
	if map and map.spiritOnly and stat.morphed:
		return

	var morphID : String = GetNextShapeID()
	if morphID.length() == 0:
		return

	var morphData : EntityData = Instantiate.FindEntityReference(morphID)
	stat.Morph(morphData)
	Launcher.Network.Server.NotifyInstancePlayers(null, self, "Morphed", [morphID, notifyMorphing])

#
func _physics_process(delta):
	super._physics_process(delta)
	UpdateLastStats()

func _ready():
	regenTimer = Timer.new()
	regenTimer.set_name("RegenTimer")
	Callback.OneShotCallback(regenTimer.tree_entered, Callback.ResetTimer, [regenTimer, EntityCommons.RegenDelay, EntityStats.Regen.bind(self)])
	add_child.call_deferred(regenTimer)

	super._ready()

#
func Respawn():
	if SkillCommons.IsAlive(self):
		return
	WorldAgent.PopAgent(self)
	var spawn: SpawnObject = Launcher.World.defaultSpawn
	position = spawn.spawn_position
	ResetNav()

	# Reset stats that were affected by death
	stat.health  = int(stat.current.maxHealth / 2.0)

	Launcher.World.Spawn(spawn.map, self)
