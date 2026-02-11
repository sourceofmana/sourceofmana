extends CommandCollection
class_name WorldCommands

# Command constructor and destructor
func RegisterCommands():
	CommandManager.Register("spawn", CommandSpawn, ActorCommons.Permission.NONE, "spawn <mob_name> <count>" )
	CommandManager.Register("warp", CommandWarp, ActorCommons.Permission.NONE, "warp <map>" )
	CommandManager.Register("goto", CommandGoto, ActorCommons.Permission.NONE, "goto <player>" )
	CommandManager.Register("godmode", CommandGodmode, ActorCommons.Permission.NONE, "godmode <on/off>" )
	CommandManager.Register("stat", CommandStat, ActorCommons.Permission.NONE, "stat <entry> <value>" )
	CommandManager.Register("level", CommandSpecificStat.bind("level"), ActorCommons.Permission.NONE, "level <value>" )
	CommandManager.Register("experience", CommandSpecificStat.bind("experience"), ActorCommons.Permission.NONE, "experience <value>" )
	CommandManager.Register("gp", CommandSpecificStat.bind("gp"), ActorCommons.Permission.NONE, "gp <value>" )
	CommandManager.Register("health", CommandSpecificStat.bind("health"), ActorCommons.Permission.NONE, "health <value>" )
	CommandManager.Register("mana", CommandSpecificStat.bind("mana"), ActorCommons.Permission.NONE, "mana <value>" )
	CommandManager.Register("stamina", CommandSpecificStat.bind("stamina"), ActorCommons.Permission.NONE, "stamina <value>" )
	CommandManager.Register("speed", CommandSpecificModifier.bind("WalkSpeed"), ActorCommons.Permission.NONE, "speed <value>" )

static func UnregisterCommands():
	CommandManager.Unregister("spawn")
	CommandManager.Unregister("warp")
	CommandManager.Unregister("goto")
	CommandManager.Unregister("godmode")
	CommandManager.Unregister("stat")
	CommandManager.Unregister("level")
	CommandManager.Unregister("experience")
	CommandManager.Unregister("gp")
	CommandManager.Unregister("health")
	CommandManager.Unregister("mana")
	CommandManager.Unregister("stamina")
	CommandManager.Unregister("speed")

# Spawn 'x' times a specific monster near the calling player
func CommandSpawn(caller : PlayerAgent, entityName : String, countStr : String) -> bool:
	if not caller:
		return false

	var count : int = countStr.to_int()
	if count <= 0:
		return false

	var entityID : int = entityName.hash()
	var entity : EntityData = DB.EntitiesDB.get(entityID, null)
	if not entity:
		return false

	var spawnedAgents : Array[MonsterAgent] = NpcCommons.Spawn(caller, entityID, count, caller.position, Vector2(200, 200))
	return not spawnedAgents.is_empty()

# Warp the current player to a specific map
func CommandWarp(caller : PlayerAgent, mapName : String, positionXStr : String = "0", positionYStr : String = "0") -> bool:
	if not caller:
		return false

	var mapID : int = mapName.hash()
	var map : WorldMap = Launcher.World.GetMap(mapID)
	if map:
		var mapPos : Vector2i = Vector2i(positionXStr.to_int(), positionYStr.to_int())
		if mapPos == Vector2i.ZERO:
			mapPos = WorldNavigation.GetRandomPosition(map)
		Launcher.World.Warp(caller, map, mapPos)
		return true
	return false

# Warp the current player to a specific map
func CommandGoto(caller : PlayerAgent, agentName : String) -> bool:
	if not caller:
		return false

	for area in Launcher.World.areas.values():
		for inst in area.instances:
			for player in inst.players:
				if player.nick == agentName:
					Launcher.World.Warp(caller, area, player.position)
					return true

	return false

# Modifiers
func CommandGodmode(caller : PlayerAgent, toggleStr : String):
	if not caller:
		return false

	if toggleStr == "on":
		return CommandSpecificModifier(caller, "10000", "DodgeRate")
	elif toggleStr == "off":
		return CommandSpecificModifier(caller, "-10000", "DodgeRate")
	return false

func CommandSpecificModifier(caller : PlayerAgent, valueStr : String, entry : String) -> bool:
	if not caller or not caller.stat or not caller.stat.modifiers:
		return false

	var effect : CellCommons.Modifier = CellCommons.Modifier.get(entry, CellCommons.Modifier.None)
	if effect == CellCommons.Modifier.None:
		return false

	for modifier in caller.stat.modifiers._modifiers:
		if modifier._effect == effect and modifier._command:
			caller.stat.modifiers.Remove(modifier)

	var value : float = valueStr.to_float()
	Network.CommandModifier(effect, value, caller.peerID)
	if value > 0.0:
		var modifier : StatModifier = StatModifier.new()
		modifier._effect = effect
		modifier._value = value
		modifier._persistent = true
		modifier._command = true
		caller.stat.modifiers.Add(modifier)

	caller.stat.RefreshAttributes()
	return true

# Stats
func CommandStat(caller : PlayerAgent, entry : String, valueStr : String) -> bool:
	return CommandSpecificStat(caller, valueStr, entry)

func CommandSpecificStat(caller : PlayerAgent, valueStr : String, entry : String) -> bool:
	if not caller or not caller.stat or entry not in caller.stat:
		return false

	caller.stat[entry] += valueStr.to_float()
	caller.stat.RefreshAttributes()
	return true
