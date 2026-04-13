extends NpcScript

#
const QUEST_ID : int						= ProgressCommons.Quest.DESERT_DEEP_XAKELBAEL

const exitDelay : float						= 8.0
const exitPosition : Vector2				= Vector2(1760, 2533)

#
var player : PlayerAgent					= null
var playerModifier : StatModifier				= null

#
func OnStart():
	Callback.PlugCallback(npc.ready, DisableAIBehaviour)

func DisableAIBehaviour():
	npc.aiBehaviour = AICommons.Behaviour.NONE
	AI.Stop(npc)

func OnAreaEnter(_player : PlayerAgent):
	if IsVisible() and _player and not _player.ownScript:
		var questState : int = _player.progress.GetQuest(QUEST_ID)
		if questState != ProgressCommons.DESERT_DEEP_XAKELBAEL.DEFEATED:
			player = _player
			Callback.OneShotCallback(player.tree_exiting, OnPlayerLeft)
			npc.Interact(player)

func OnPlayerLeft():
	RemovePlayerModifier()
	if player:
		NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.DESERT_DEEP_XAKELBAEL.INACTIVE)
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
	NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.DESERT_DEEP_XAKELBAEL.FIGHTING)

	SetVisible(false)
	AddPlayerModifier()

	var mobs : Array[MonsterAgent] = Spawn(npc.data._id, 1, npc.position, Vector2i.DOWN)
	if not mobs.is_empty():
		var monsterAgent : MonsterAgent = mobs[0]
		monsterAgent.agent_killed.connect(OnMonsterKilled)
		AI.Refresh(monsterAgent)

func OnMonsterKilled(mob : BaseAgent):
	RemovePlayerModifier()

	npc.position = mob.position
	RemoveAgent(mob)
	SetState(ActorCommons.State.DEATH)
	SetVisible(true)

	NpcCommons.SetQuest(player, QUEST_ID, ProgressCommons.DESERT_DEEP_XAKELBAEL.DEFEATED)

	if player and ActorCommons.IsAlive(player) and not player.ownScript:
		player.AddScript(npc)
		if player.ownScript:
			player.ownScript.ApplyStep()

func RunAway():
	if player:
		Callback.ClearOneShot(player.tree_exiting)
		player = null

	SetState(ActorCommons.State.IDLE)

	AddModifier(CellCommons.Modifier.WalkSpeed, 200)

	AI.Reset(npc)
	npc.WalkToward(exitPosition)
	AddTimer(npc, exitDelay, WorldAgent.RemoveAgent.bind(npc))
