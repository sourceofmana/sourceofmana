extends CommandCollection
class_name WorldCommands

# Command constructor and destructor
func RegisterCommands():
	CommandManager.Register("spawn", CommandSpawn, ActorCommons.Permission.NONE, "spawn <mob_name> <count>" )
	CommandManager.Register("warp", CommandWarp, ActorCommons.Permission.NONE, "warp <map>" )
	CommandManager.Register("goto", CommandGoto, ActorCommons.Permission.NONE, "goto <player>" )
	CommandManager.Register("godmode", CommandGodmode, ActorCommons.Permission.NONE, "godmode <on/off>" )

static func UnregisterCommands():
	CommandManager.Unregister("spawn")
	CommandManager.Unregister("warp")
	CommandManager.Unregister("goto")
	CommandManager.Unregister("godmode")

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
func CommandWarp(caller : PlayerAgent, mapName : String) -> bool:
	if not caller:
		return false

	var mapID : int = mapName.hash()
	var map : WorldMap = Launcher.World.GetMap(mapID)
	if map:
		var mapPos : Vector2 = WorldNavigation.GetRandomPosition(map)
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

#
var godmodeModifier : StatModifier = null
func CommandGodmode(caller : PlayerAgent, value : String):
	if not caller:
		return false

	if not godmodeModifier:
		godmodeModifier = StatModifier.new()
		godmodeModifier._effect = CellCommons.Modifier.DodgeRate
		godmodeModifier._value = 100000.0
		godmodeModifier._persistent = true

	if value == "on":
		caller.stat.modifiers.Remove(godmodeModifier)
		caller.stat.modifiers.Add(godmodeModifier)
		caller.stat.RefreshAttributes()
		return true
	elif value == "off":
		caller.stat.modifiers.Remove(godmodeModifier)
		caller.stat.RefreshAttributes()
		return true
	return false
