extends NpcScript
class_name SoulMenhirGlobal

#
const REGEN_HEALTH_BONUS : int = 3
const REGEN_MANA_BONUS : int = 3
const REGEN_STAMINA_BONUS : int = 3

var playerModifiers : Dictionary[int, Array] = {}

#
func SaveRespawn(player : PlayerAgent):
	var map : WorldMap = WorldAgent.GetMapFromAgent(npc)
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(npc)
	if map and inst:
		var respawnPos : Vector2i = WorldNavigation.GetRandomPositionAABB(inst, Vector2i(npc.position), Vector2i(64, 64))
		if respawnPos != Vector2i.ZERO:
			player.respawnDestination = Destination.new(map.id, Vector2(respawnPos))
			NpcCommons.PushNotification(player, "You feel the mana power growing inside you!")

func OnAreaEnter(player : PlayerAgent):
	if not player or not ActorCommons.IsAlive(player):
		return

	var playerRID : int = player.get_rid().get_id()
	if playerModifiers.has(playerRID):
		return

	var mods : Array[StatModifier] = []
	mods.append(AddModifier(CellCommons.Modifier.RegenHealth, REGEN_HEALTH_BONUS, player))
	mods.append(AddModifier(CellCommons.Modifier.RegenMana, REGEN_MANA_BONUS, player))
	mods.append(AddModifier(CellCommons.Modifier.RegenStamina, REGEN_STAMINA_BONUS, player))
	playerModifiers[playerRID] = mods

func OnAreaExit(player : PlayerAgent):
	if not player:
		return

	var playerRID : int = player.get_rid().get_id()
	if not playerModifiers.has(playerRID):
		return

	for mod in playerModifiers[playerRID]:
		RemoveModifier(mod, player)
	playerModifiers.erase(playerRID)
