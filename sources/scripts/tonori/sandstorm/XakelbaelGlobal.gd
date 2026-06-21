extends NpcScript

const QUEST_ID : int						= ProgressCommons.Quest.MINE_EXPLORATION

const exitDelay : float						= 8.0
const exitPosition : Vector2				= Vector2(1760, 2533)

#
var player : PlayerAgent					= null
var playerModifier : StatModifier			= null
var monster : MonsterAgent					= null

#
func OnAreaEnter(_player : PlayerAgent):
	if IsVisible() and _player and not _player.ownScript:
		var questState : int = _player.progress.GetQuest(QUEST_ID)
		if questState == ProgressCommons.MINE_EXPLORATION.STRANGER_SPOTTED:
			player = _player
			Callback.OneShotCallback(player.tree_exiting, OnPlayerLeft)
			npc.Interact(player)

func OnPlayerLeft():
	RemovePlayerModifier()
	if monster:
		RemoveAgent(monster)
		monster = null
	SetVisible(true)
	if player:
		var questState : int = player.progress.GetQuest(QUEST_ID)
		if questState == ProgressCommons.MINE_EXPLORATION.FIGHTING:
			NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.MINE_EXPLORATION.STRANGER_SPOTTED)
		player = null

# Player modifier
func AddPlayerModifier():
	if not playerModifier and player:
		playerModifier = AddModifier(CellCommons.Modifier.DodgeRate, 10000, player)

func RemovePlayerModifier():
	if playerModifier and player:
		RemoveModifier(playerModifier, player)
	playerModifier = null

# Actions
func StartFight():
	NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.MINE_EXPLORATION.FIGHTING)

	SetVisible(false)
	AddPlayerModifier()

	var mobs : Array[MonsterAgent] = Spawn(npc.data._id, 1, npc.position, Vector2i.DOWN)
	if not mobs.is_empty():
		monster = mobs[0]
		monster.agent_killed.connect(OnMonsterKilled)
		AI.Refresh(monster)

func OnMonsterKilled(mob : BaseAgent):
	monster = null
	RemovePlayerModifier()

	npc.position = mob.position
	RemoveAgent(mob)
	SetState(ActorCommons.State.DEATH)
	SetVisible(true)

	if not player:
		return

	NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.MINE_EXPLORATION.DEFEATED)
	NpcCommons.AddItem(player, DB.GetCellHash("Sandstorm Kano"))

	if ActorCommons.IsAlive(player) and not player.ownScript:
		player.AddScript(npc)
		if player.ownScript:
			player.ownScript.ApplyStep()

func TriggerManaTree():
	if player and ActorCommons.IsAlive(player) and not player.ownScript:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(npc)
		if inst:
			for npcAgent : AIAgent in inst.npcs:
				if npcAgent and npcAgent.nick == "Mana Tree":
					player.AddScript(npcAgent)
					if player.ownScript:
						player.ownScript.ApplyStep()
					break

func RunAway():
	if player:
		Callback.ClearOneShot(player.tree_exiting)
		player = null

	var map : WorldMap = WorldAgent.GetMapFromAgent(npc)
	if map and not npc.agent:
		npc.aiBehaviour = AICommons.Behaviour.NONE
		npc.agent = FileSystem.LoadEntityComponent("navigations/NPAgent")
		npc.agent.set_radius(npc.data._radius)
		npc.agent.set_neighbor_distance(npc.data._radius * 2.0)
		npc.agent.set_navigation_map(map.mapRID)
		npc.add_child(npc.agent)
		npc.RefreshWalkSpeed()

	SetVisible(true)
	SetState(ActorCommons.State.IDLE)
	AddModifier(CellCommons.Modifier.WalkSpeed, 200)
	AI.Stop(npc)
	npc.WalkToward(exitPosition)
	AddTimer(npc, exitDelay, WorldAgent.RemoveAgent.bind(npc))
