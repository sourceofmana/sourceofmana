extends CommandCollection
class_name WorldCommands

# Command constructor and destructor
func RegisterCommands():
	CommandManager.Register("spawn", CommandSpawn, ActorCommons.Permission.GM, "spawn <mob_name> <count>" )
	CommandManager.Register("warp", CommandWarp, ActorCommons.Permission.MODERATOR, "warp <map> <posX> <posY>" )
	CommandManager.Register("goto", CommandGoto, ActorCommons.Permission.MODERATOR, "goto <player>" )
	CommandManager.Register("godmode", CommandGodmode, ActorCommons.Permission.MODERATOR, "godmode <on/off>" )
	CommandManager.Register("stat", CommandStat, ActorCommons.Permission.ADMIN, "stat <entry> <value>" )
	CommandManager.Register("level", CommandSpecificStat.bind("level"), ActorCommons.Permission.ADMIN, "level <value>" )
	CommandManager.Register("experience", CommandSpecificStat.bind("experience"), ActorCommons.Permission.ADMIN, "experience <value>" )
	CommandManager.Register("gp", CommandSpecificStat.bind("gp"), ActorCommons.Permission.GM, "gp <value>" )
	CommandManager.Register("health", CommandSpecificStat.bind("health"), ActorCommons.Permission.MODERATOR, "health <value>" )
	CommandManager.Register("mana", CommandSpecificStat.bind("mana"), ActorCommons.Permission.MODERATOR, "mana <value>" )
	CommandManager.Register("stamina", CommandSpecificStat.bind("stamina"), ActorCommons.Permission.MODERATOR, "stamina <value>" )
	CommandManager.Register("speed", CommandSpecificModifier.bind("WalkSpeed"), ActorCommons.Permission.ADMIN, "speed <value>" )
	CommandManager.Register("localbroadcast", CommandLocalBroadcast, ActorCommons.Permission.MODERATOR, "localbroadcast <text>" )
	CommandManager.Register("broadcast", CommandBroadcast, ActorCommons.Permission.MODERATOR, "broadcast <text>" )
	CommandManager.Register("quest", CommandQuest, ActorCommons.Permission.ADMIN, "quest <name> <state>" )
	CommandManager.Register("bestiary", CommandBestiary, ActorCommons.Permission.ADMIN, "bestiary <name> <state>" )
	CommandManager.Register("item", CommandItem, ActorCommons.Permission.GM, "item <name> <count> <custom>" )
	CommandManager.Register("killall", CommandKillAll, ActorCommons.Permission.ADMIN, "killall <filter>" )
	CommandManager.Register("kill", CommandKill, ActorCommons.Permission.MODERATOR, "kill <nick>" )
	CommandManager.Register("revive", CommandRevive, ActorCommons.Permission.MODERATOR, "revive <nick>" )

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
	CommandManager.Unregister("localbroadcast")
	CommandManager.Unregister("broadcast")
	CommandManager.Unregister("quest")
	CommandManager.Unregister("bestiary")
	CommandManager.Unregister("item")
	CommandManager.Unregister("killall")
	CommandManager.Unregister("kill")
	CommandManager.Unregister("revive")

# Spawn 'x' times a specific monster near the calling player
func CommandSpawn(caller : PlayerAgent, entityName : String, countStr : String = "1") -> bool:
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

	for areaIdx in Launcher.World.areas:
		var area = Launcher.World.areas[areaIdx]
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

# Broadcast
func CommandLocalBroadcast(caller : PlayerAgent, text : String) -> bool:
	if not caller:
		return false

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(caller)
	if inst:
		Network.NotifyInstance(inst, "PushNotification", [text])
		return true
	return false

func CommandBroadcast(caller : PlayerAgent, text : String) -> bool:
	if not caller:
		return false

	for areaIdx in Launcher.World.areas:
		var area = Launcher.World.areas[areaIdx]
		for inst in area.instances:
			Network.NotifyGlobal("PushNotification", [text])
	return true

# Progress
func CommandQuest(caller : PlayerAgent, questStr : String, stateStr : String) -> bool:
	if not caller or not caller.progress:
		return false

	var questID : int = questStr.to_int()
	var state : int = stateStr.to_int()
	if questID in DB.QuestsDB:
		NpcCommons.SetQuest(caller, questID, state)
		return true
	return false

func CommandBestiary(caller : PlayerAgent, monsterName : String, countStr : String) -> bool:
	if not caller or not caller.progress:
		return false

	var monsterID : int = monsterName.hash()
	var count : int = countStr.to_int()
	if monsterID in DB.EntitiesDB:
		NpcCommons.AddBestiary(caller, monsterID, count)
		return true
	return false

# Inventory
func CommandItem(caller : PlayerAgent, itemName : String, countStr : String = "1", customField : String = "") -> bool:
	if not caller or not caller.progress or not DB.HasCellHash(itemName):
		return false

	var itemID : int = itemName.hash()
	var count : int = countStr.to_int()
	if count > 0:
		return NpcCommons.AddItem(caller, itemID, count, customField)
	elif count < 0:
		return NpcCommons.RemoveItem(caller, itemID, -count, customField)
	return false

# Death
func CommandKillAll(caller : PlayerAgent, filter : String = "") -> bool:
	if not caller:
		return false

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(caller)
	if inst:
		for mob in inst.mobs:
			if mob and (filter.is_empty() or mob.nick == filter):
				mob.Kill()
	return true

func CommandKill(caller : PlayerAgent, nick : String) -> bool:
	if not caller:
		return false

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(caller)
	if inst:
		for player in inst.players:
			if player and player.nick == nick:
				player.Kill()
				return true
	return false

func CommandRevive(caller : PlayerAgent, nick : String) -> bool:
	if not caller:
		return false

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(caller)
	if inst:
		for player in inst.players:
			if player and player.nick == nick:
				player.Revive()
				return true
	return false
