extends CommandCollection
class_name WorldCommands

# Command constructor and destructor
func RegisterCommands():
	CommandManager.Register("spawn", CommandSpawn, ActorCommons.Permission.NONE, "spawn <mob_name> <count>" )
	CommandManager.Register("warp", CommandWarp, ActorCommons.Permission.NONE, "warp <map>" )

static func UnregisterCommands():
	CommandManager.Unregister("spawn")
	CommandManager.Unregister("warp")

# Spawn 'x' times a specific monster near the calling player
func CommandSpawn(caller : PlayerAgent, entityName : String, countStr : String) -> bool:
	if not caller:
		return false

	var count : int = countStr.to_int()
	if count <= 0:
		return false

	var entityID : int = entityName.hash()
	var entity : EntityData = DB.GetEntity(entityID)
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
