extends NpcScript
class_name WaterPondGlobal

#
const QUEST_ID : int									= ProgressCommons.Quest.SNAKE_PIT_BITING_THIRST
const MAX_BITES : int									= 5
const FILL_TIME : float									= 5.0
const FILL_TICKS : int									= 10
const FILL_TICK_TIME : float							= FILL_TIME / FILL_TICKS
const MOVE_TOLERANCE : float							= 8.0

# Per-player bite counters [PlayerRID, BiteCount]
static var biteCounters : Dictionary[int, int]			= {}

# Signal handling
static func StartJugTransport(player : PlayerAgent):
	var rid : int = player.get_rid().get_id()
	biteCounters[rid] = MAX_BITES
	if not player.agent_damaged.is_connected(OnBite):
		player.agent_damaged.connect(OnBite)

static func StopJugTransport(player : PlayerAgent):
	var rid : int = player.get_rid().get_id()
	biteCounters.erase(rid)
	if player.agent_damaged.is_connected(OnBite):
		player.agent_damaged.disconnect(OnBite)

# Biting handling
static func OnBite(player : PlayerAgent, value : int):
	if value == 0 or player.progress.GetQuest(QUEST_ID) != ProgressCommons.SNAKE_PIT_BITING_THIRST.STARTED:
		return

	var rid : int = player.get_rid().get_id()
	if not biteCounters.has(rid):
		return

	var remaining : int = biteCounters[rid] - 1
	biteCounters[rid] = remaining
	NpcCommons.PushTracker(player, "Jug Integrity", remaining, MAX_BITES, "%")
	if remaining <= 0:
		Spill(player)

static func Spill(player : PlayerAgent):
	StopJugTransport(player)
	NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.SNAKE_PIT_BITING_THIRST.STARTED)
	NpcCommons.ClearTracker(player)
	NpcCommons.PushNotification(player, "You were bitten too many times! Return to the water source to refill.")

# Jug filling handling
func OnFillTick(player : PlayerAgent, startPos : Vector2, tick : int):
	if player.position.distance_to(startPos) > MOVE_TOLERANCE:
		NpcCommons.ClearTracker(player)
	else:
		if tick >= FILL_TICKS:
			CompleteFill(player)
		else:
			NpcCommons.PushTracker(player, "Filling...", tick, FILL_TICKS, "%")
			ScheduleTick(player, startPos, tick)

func ScheduleTick(player : PlayerAgent, startPos : Vector2, tick : int):
	AddTimer(own, FILL_TICK_TIME, OnFillTick.bind(player, startPos, tick + 1), player.nick)

func CompleteFill(player : PlayerAgent):
	StartJugTransport(player)
	NpcCommons.PushTracker(player, "Jug Integrity", MAX_BITES, MAX_BITES, "%")
