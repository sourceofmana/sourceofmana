extends NpcScript
class_name CastleRedQueenGlobal

const SBIRE_SPAWN_POSITION : Vector2 = Vector2(1600, 1536)
const SBIRE_SPAWN_RADIUS : Vector2 = Vector2(32, 32)

static var spawnedGuards : Array[MonsterAgent] = []
static var trackedPlayers : Dictionary[int, bool] = {}

#
func OnAreaEnter(player : PlayerAgent):
	if not ActorCommons.IsAlive(player):
		return

	var playerRID : int = player.get_rid().get_id()
	if trackedPlayers.has(playerRID):
		return

	trackedPlayers[playerRID] = true

	if spawnedGuards.is_empty():
		spawnedGuards = Spawn("Tulimshar Sbire".hash(), 1, SBIRE_SPAWN_POSITION, SBIRE_SPAWN_RADIUS)

	for guard in spawnedGuards:
		if is_instance_valid(guard):
			guard.AddAttacker(player)
			if guard.is_node_ready():
				ActivateGuard(guard)
			else:
				Callback.OneShotCallback(guard.ready, ActivateGuard, [guard])

	player.agent_killed.connect(func(_killed : BaseAgent): Cleanup(playerRID), CONNECT_ONE_SHOT)
	player.tree_exiting.connect(func(): Cleanup(playerRID), CONNECT_ONE_SHOT)

static func ActivateGuard(guard : MonsterAgent):
	if is_instance_valid(guard):
		guard.aiBehaviour = AICommons.Behaviour.AGGRESSIVE

static func Cleanup(playerRID : int):
	trackedPlayers.erase(playerRID)

	if not trackedPlayers.is_empty():
		return

	for guard in spawnedGuards:
		if guard and is_instance_valid(guard):
			WorldAgent.RemoveAgent.call_deferred(guard)
	spawnedGuards.clear()
