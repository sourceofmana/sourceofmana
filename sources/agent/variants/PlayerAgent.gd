extends BaseAgent
class_name PlayerAgent

#
var lastStat : EntityStats				= EntityStats.new()

#
static func GetEntityType() -> EntityCommons.Type: return EntityCommons.Type.PLAYER

#
func UpdateStats():
	var peerID : int = Launcher.Network.Server.GetRid(self)
	if peerID == NetworkCommons.RidUnknown:
		return

	if lastStat.level != stat.level or \
	lastStat.experience != stat.experience:
		stat.UpdatePlayerVars(peerID)
		lastStat.level				= stat.level
		lastStat.experience			= stat.experience

	if lastStat.health != stat.health or \
	lastStat.mana != stat.mana or \
	lastStat.stamina != stat.stamina or \
	lastStat.weight != stat.weight or \
	lastStat.morphed != stat.morphed:
		stat.UpdateActiveStats(peerID)
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
		stat.UpdatePersonalStats(peerID)
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
func _specific_process():
	UpdateStats()

#
func Respawn():
	if SkillCommons.IsAlive(self):
		return
	WorldAgent.PopAgent(self)
	var spawn: SpawnObject = Launcher.World.defaultSpawn
	position = spawn.spawn_position
	ResetNav()

	# Reset stats that were affected by death
	stat.health  = int(Launcher.Player.stat.current.maxHealth / 2.0)
	stat.mana 	 = int(Launcher.Player.stat.current.maxMana / 2.0)
	stat.stamina = int(Launcher.Player.stat.current.maxStamina / 2.0)

	Launcher.World.Spawn(spawn.map, self)
