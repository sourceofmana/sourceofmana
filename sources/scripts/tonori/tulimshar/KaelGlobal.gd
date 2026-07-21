extends NpcScript
class_name KaelGlobal

const PEYOTE_REQUIRED : int					= 5
const MAGGOT_REQUIRED : int					= 5

# Entity IDs
var peyoteID : int							= "Peyote".hash()
var maggotID : int							= "Maggot".hash()

# Per-player kill counters and tracker
var peyoteKills : Dictionary[int, int]		= {}
var maggotKills : Dictionary[int, int]		= {}
var trackedTargets : Dictionary[int, int]	= {}

#
func TrackPlayer(player : PlayerAgent):
	if not player:
		return

	var rid : int = player.get_rid().get_id()
	if trackedTargets.has(rid):
		return

	peyoteKills[rid] = 0
	maggotKills[rid] = 0
	trackedTargets[rid] = DB.UnknownHash

	if not player.enemy_killed.is_connected(OnEnemyKilled):
		player.enemy_killed.connect(OnEnemyKilled)
	if not player.target_selected.is_connected(OnTargetSelected):
		player.target_selected.connect(OnTargetSelected)
	var exitCallback : Callable = OnPlayerDisconnected.bind(player)
	if not Network.online_player_disconnected.is_connected(exitCallback):
		Network.online_player_disconnected.connect(exitCallback, ConnectFlags.CONNECT_ONE_SHOT)

func UntrackPlayer(player : PlayerAgent):
	if not player:
		return

	var rid : int = player.get_rid().get_id()

	if player.enemy_killed.is_connected(OnEnemyKilled):
		player.enemy_killed.disconnect(OnEnemyKilled)
	if player.target_selected.is_connected(OnTargetSelected):
		player.target_selected.disconnect(OnTargetSelected)
	var exitCallback : Callable = OnPlayerDisconnected.bind(player)
	if Network.online_player_disconnected.is_connected(exitCallback):
		Network.online_player_disconnected.disconnect(exitCallback)

	peyoteKills.erase(rid)
	maggotKills.erase(rid)
	trackedTargets.erase(rid)

func OnPlayerDisconnected(_playerName : String, player : PlayerAgent):
	UntrackPlayer(player)

func GetKillCount(player : PlayerAgent, monsterID : int) -> int:
	if not player:
		return 0

	var rid : int = player.get_rid().get_id()
	match monsterID:
		peyoteID:
			return peyoteKills.get(rid, 0)
		maggotID:
			return maggotKills.get(rid, 0)
	return 0

#
func OnEnemyKilled(player : PlayerAgent, monsterID : int):
	if not player:
		return

	var rid : int = player.get_rid().get_id()
	if (monsterID != peyoteID and monsterID != maggotID) or not trackedTargets.has(rid):
		return

	match monsterID:
		peyoteID:
			if peyoteKills[rid] < PEYOTE_REQUIRED:
				peyoteKills[rid] += 1
		maggotID:
			if maggotKills[rid] < MAGGOT_REQUIRED:
				maggotKills[rid] += 1

	if trackedTargets.get(rid, DB.UnknownHash) == monsterID:
		RefreshTracker(player, monsterID)

func OnTargetSelected(player : PlayerAgent, target : BaseAgent):
	if not player or not target:
		return

	var rid : int = player.get_rid().get_id()
	if not trackedTargets.has(rid):
		return

	var monsterID : int = target.data._id if target and target.data else DB.UnknownHash
	if monsterID != peyoteID and monsterID != maggotID:
		return

	trackedTargets[rid] = monsterID
	RefreshTracker(player, monsterID)

#
func RefreshTracker(player : PlayerAgent, monsterID : int = DB.UnknownHash):
	match monsterID:
		peyoteID:
			NpcCommons.PushTracker(player, "Peyote", GetKillCount(player, monsterID), PEYOTE_REQUIRED)
		maggotID:
			NpcCommons.PushTracker(player, "Maggot", GetKillCount(player, monsterID), MAGGOT_REQUIRED)
		_:
			NpcCommons.ClearTracker(player)
