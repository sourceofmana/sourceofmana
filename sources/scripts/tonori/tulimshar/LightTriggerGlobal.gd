extends NpcScript
class_name TulimsharWestWallLightTrigerGlobal

#
const QUEST_ID : int = ProgressCommons.Quest.TULIMSHAR_OLD_FRIENDSHIP
const GUARD_SPEED_BOOST : int = 200
const APPROACH_DISTANCE : float = 48.0

#
static var activeCatches : Dictionary[int, NpcAgent] = {}

#
func OnAreaEnter(player : PlayerAgent):
	CallGuard(player)

static func CallGuard(player : PlayerAgent):
	if not ActorCommons.IsAlive(player):
		return

	var playerRID : int = player.get_rid().get_id()
	if activeCatches.has(playerRID):
		return

	var questState : int = player.progress.GetQuest(QUEST_ID)
	if questState >= ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.LETTERS_DELIVERED:
		return

	if player.SetState(ActorCommons.State.TRIGGER):
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(player)
		if inst:
			var guard : BaseAgent = SpawnGuard(inst)
			if guard:
				activeCatches[playerRID] = guard
				NpcCommons.PushNotification(player, "A guard saw you!")
				Callback.AddCallback(player.tree_exiting, Cleanup, [player, guard, playerRID], ConnectFlags.CONNECT_ONE_SHOT)
				Callback.OneShotCallback(guard.ready, OnGuardReady.bind(player, guard, playerRID))

static func SpawnGuard(inst : WorldInstance) -> BaseAgent:
	var spawn : SpawnObject = SpawnObject.new()
	spawn.map = inst.map
	spawn.type = "Npc"
	spawn.nick = "Tulimshar Guard" if randi() % 2 == 0 else "Tulimshar Sbire"
	spawn.id = spawn.nick.hash()
	spawn.spawn_position = Vector2i(2688, 1472) # tile (84, 46)
	spawn.spawn_offset = Vector2i.DOWN
	spawn.player_script = "tonori/tulimshar/PatrolGuardCaught.gd"
	return WorldAgent.CreateAgent(spawn, inst.id)

static func OnGuardReady(player : PlayerAgent, guard : NpcAgent, playerRID : int):
	if not guard or not ActorCommons.IsAlive(player):
		Cleanup(player, guard, playerRID)
		return

	var guardRID : int = guard.get_rid().get_id()
	Launcher.World.BulkPreload(guard, guardRID, player.peerID)
	player.CheckVisibility(guard)

	# Wait one full update cycle for the SetData to be called
	StartGuardNavigation.call_deferred(player, guard, playerRID)

static func StartGuardNavigation(player : PlayerAgent, guard : NpcAgent, playerRID : int):
	if not guard or not ActorCommons.IsAlive(player):
		Cleanup(player, guard, playerRID)
		return

	NpcCommons.AddModifier(guard, CellCommons.Modifier.WalkSpeed, GUARD_SPEED_BOOST)

	AI.Stop(guard)

	# Check if in correct distance to start the guard interaction
	if (guard.position - player.position).length() < APPROACH_DISTANCE / 2.0:
		OnGuardArrived(player, guard, playerRID)
	# Stop right before the player position but still within the trigger position
	else:
		var stopPos : Vector2 = player.position + (guard.position - player.position).normalized() * APPROACH_DISTANCE / 2.0
		guard.WalkToward(stopPos)
		Callback.OneShotCallback(guard.agent.navigation_finished, OnGuardArrived.bind(player, guard, playerRID))

static func OnGuardArrived(player : PlayerAgent, guard : NpcAgent, playerRID : int):
	if not guard or not ActorCommons.IsAlive(player):
		Cleanup(player, guard, playerRID)
		return

	guard.Interact(player)

static func Cleanup(player : PlayerAgent, guard : NpcAgent, playerRID : int):
	activeCatches.erase(playerRID)
	if player and is_instance_valid(player):
		if player.ownScript:
			NpcCommons.ToggleContext(player, false)
			player.ClearScript()
		if player.state == ActorCommons.State.TRIGGER:
			player.SetState(ActorCommons.State.TRIGGER)
	if guard and is_instance_valid(guard):
		WorldAgent.RemoveAgent.call_deferred(guard)
