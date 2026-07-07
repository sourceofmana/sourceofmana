extends NpcScript

# Constants
const QUEST_ID : int = ProgressCommons.Quest.SHIP_PETER_BOUNTY

const HOLD_SPAWN_MAP : StringName			= "Ship Hold"
const SECOND_DECK_MAP : StringName			= "Ship Second Deck"
const RETURN_POS : Vector2					= Vector2(68 * 32, 36 * 32)

const INSTANCE_TIMEOUT_SECS : float			= 2.0 * 60.0
const WARN_INSTANCE_TIMEOUT_SECS : float	= INSTANCE_TIMEOUT_SECS - 30.0

const SPAWN_DELAY : float					= 2.0
const RESPAWN_DELAY : float					= 1.0 * 60.0
const VICTORY_DELAY : float					= 5.0
const DAILY_COOLDOWN_SECS : float			= 24.0 * 60 * 60

# Data saved across every player runs
class RunData:
	var player : PlayerAgent	= null
	var spawnObj : SpawnObject	= null
	var nextState : int			= 0
	var monsterID : int			= 0
	var monsterCount : int		= 0
	var isDaily : bool			= false
	var aliveCount : int		= 0
	var warnTimer : Timer		= null
	var timeoutTimer : Timer	= null

# Mission states
var runs : Dictionary[int, RunData]			= {}
var dailyCooldowns : Dictionary[int, float]	= {}

# Player-script accessors
func IsInProgress(player : PlayerAgent) -> bool:
	return runs.has(player.get_rid().get_id())

func CanRunDailyQuest(playerRID : int) -> bool:
	var expiry : float = dailyCooldowns.get(playerRID, 0.0)
	return Time.get_unix_time_from_system() > expiry

func StartRun(player : PlayerAgent, nextState : int, monsterID : int, monsterCount : int):
	var playerRID : int = player.get_rid().get_id()
	if runs.has(playerRID):
		return

	var run : RunData = RunData.new()
	run.player = player
	run.nextState = nextState
	run.monsterID = monsterID
	run.monsterCount = monsterCount
	run.aliveCount = monsterCount
	run.isDaily = (nextState == ProgressCommons.SHIP_PETER_BOUNTY.ALL_DONE and
			player.progress.GetQuest(QUEST_ID) == ProgressCommons.SHIP_PETER_BOUNTY.ALL_DONE)
	runs[playerRID] = run

	player.tree_exiting.connect(EndRun.bind(playerRID), CONNECT_ONE_SHOT)
	player.agent_killed.connect(OnPlayerDied, CONNECT_ONE_SHOT)

	AddTimer(npc, SPAWN_DELAY, SpawnMonstersForPlayer.bind(playerRID))

# Spawns
func SpawnMonstersForPlayer(playerRID : int):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	var holdMap : WorldMap = Launcher.World.GetMap(HOLD_SPAWN_MAP.hash())
	if not holdMap:
		EndRun(playerRID)
		return

	var inst : WorldInstance = holdMap.instances.get(playerRID, null)
	if not inst:
		EndRun(playerRID)
		return

	run.spawnObj = SpawnObject.new()
	run.spawnObj.map = holdMap
	run.spawnObj.type = "Monster"
	run.spawnObj.id = run.monsterID
	run.spawnObj.is_global = true
	run.spawnObj.is_persistant = false

	run.warnTimer = Callback.SelfDestructTimer(inst.timers, WARN_INSTANCE_TIMEOUT_SECS, OnWarnTimeout.bind(playerRID))
	run.timeoutTimer = Callback.SelfDestructTimer(inst.timers, INSTANCE_TIMEOUT_SECS, OnRunTimeout.bind(playerRID))

	NpcCommons.PushTracker(run.player, "Monsters", 0, run.monsterCount)
	for _monsterIdx in run.monsterCount:
		SpawnMonster(playerRID, holdMap, inst)

func SpawnMonster(playerRID : int, holdMap : WorldMap, inst : WorldInstance):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	var monster : BaseAgent = WorldAgent.CreateAgent(run.spawnObj, playerRID)
	if monster:
		monster.agent_killed.connect(OnMonsterKilled.bind(playerRID, holdMap, inst), CONNECT_ONE_SHOT)

# Mission in progress
func OnMonsterKilled(_killed : BaseAgent, playerRID : int, holdMap : WorldMap, inst : WorldInstance):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	run.aliveCount -= 1
	NpcCommons.PushTracker(run.player, "Monsters", run.monsterCount - run.aliveCount, run.monsterCount)

	if run.aliveCount == 0:
		OnVictory(playerRID)
	elif is_instance_valid(inst) and inst.timers:
		Callback.SelfDestructTimer(inst.timers, RESPAWN_DELAY, RespawnMonster.bind(playerRID, holdMap, inst))

func RespawnMonster(playerRID : int, holdMap : WorldMap, inst : WorldInstance):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	run.aliveCount += 1
	NpcCommons.PushTracker(run.player, "Monsters", run.monsterCount - run.aliveCount, run.monsterCount)
	SpawnMonster(playerRID, holdMap, inst)

# Mission complete
func OnVictory(playerRID : int):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	var player : PlayerAgent = run.player
	if not player or not is_instance_valid(player):
		EndRun(playerRID)
		return

	ClearRunTimers(run)
	NpcCommons.PushNotification(player, "The hold is clear. Time to leave this place")

	var holdMap : WorldMap = Launcher.World.GetMap(HOLD_SPAWN_MAP.hash())
	var inst : WorldInstance = holdMap.instances.get(playerRID, null) if holdMap else null
	if inst:
		Callback.SelfDestructTimer(inst.timers, VICTORY_DELAY, OnVictoryWarpBack.bind(playerRID))
	else:
		OnVictoryWarpBack(playerRID)

func OnVictoryWarpBack(playerRID : int):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	var player : PlayerAgent = run.player
	if not player or not is_instance_valid(player):
		EndRun(playerRID)
		return

	GiveRewards(playerRID, player)
	NpcCommons.Warp(player, SECOND_DECK_MAP.hash(), RETURN_POS)

	EndRun(playerRID)

func GiveRewards(playerRID : int, player : PlayerAgent):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	if run.isDaily:
		NpcCommons.AddExp(player, 100)
		NpcCommons.AddGP(player, 500)
		dailyCooldowns[playerRID] = Time.get_unix_time_from_system() + DAILY_COOLDOWN_SECS
	else:
		match run.nextState:
			ProgressCommons.SHIP_PETER_BOUNTY.WAVE_ONE_DONE:
				NpcCommons.AddExp(player, 100)
				NpcCommons.AddGP(player, 500)
				NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.SHIP_PETER_BOUNTY.WAVE_ONE_DONE)
			ProgressCommons.SHIP_PETER_BOUNTY.WAVE_TWO_DONE:
				NpcCommons.AddExp(player, 150)
				NpcCommons.AddGP(player, 1000)
				NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.SHIP_PETER_BOUNTY.WAVE_TWO_DONE)
			ProgressCommons.SHIP_PETER_BOUNTY.ALL_DONE:
				NpcCommons.AddExp(player, 250)
				NpcCommons.AddGP(player, 1500)
				NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.SHIP_PETER_BOUNTY.ALL_DONE)
				dailyCooldowns[playerRID] = Time.get_unix_time_from_system() + DAILY_COOLDOWN_SECS

# Mission failed
func OnRunTimeout(playerRID : int):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	var player : PlayerAgent = run.player
	if player and is_instance_valid(player):
		NpcCommons.PushNotification(player, "The foul air overwhelms you. You stagger back up to the deck.")
		NpcCommons.Warp(player, SECOND_DECK_MAP.hash(), RETURN_POS)

	EndRun(playerRID)

func OnWarnTimeout(playerRID : int):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	var player : PlayerAgent = run.player
	if player and is_instance_valid(player):
		NpcCommons.PushNotification(player, "This air is foul, better finish this fast.")

	run.warnTimer = null

func OnPlayerDied(player : BaseAgent):
	EndRun(player.get_rid().get_id())

# Clean up
func ClearRunTimers(run : RunData):
	if run.warnTimer and not run.warnTimer.is_queued_for_deletion():
		run.warnTimer.stop()
		run.warnTimer.queue_free()
	run.warnTimer = null
	if run.timeoutTimer and not run.timeoutTimer.is_queued_for_deletion():
		run.timeoutTimer.stop()
		run.timeoutTimer.queue_free()
	run.timeoutTimer = null

func EndRun(playerRID : int):
	var run : RunData = runs.get(playerRID)
	if not run:
		return

	if run.player:
		if run.player.agent_killed.is_connected(OnPlayerDied):
			run.player.agent_killed.disconnect(OnPlayerDied)
		if run.player.tree_exiting.is_connected(EndRun.bind(playerRID)):
			run.player.tree_exiting.disconnect(EndRun.bind(playerRID))

	ClearRunTimers(run)
	NpcCommons.ClearTracker(run.player)
	runs.erase(playerRID)
