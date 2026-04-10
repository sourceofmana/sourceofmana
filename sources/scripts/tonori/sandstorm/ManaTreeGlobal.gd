extends NpcScript

#
const QUEST_ID : int				= ProgressCommons.Quest.DESERT_DEEP_XAKELBAEL

#
func OnAreaEnter(player : PlayerAgent):
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(npc)
	if not inst or inst.id != player.get_rid().get_id():
		return

	var questState : int = player.progress.GetQuest(QUEST_ID)
	if questState != ProgressCommons.DESERT_DEEP_XAKELBAEL.DEFEATED:
		SpawnXakelbael(inst)

	npc.RemoveTrigger()

func SpawnXakelbael(inst : WorldInstance):
	var spawn : SpawnObject = SpawnObject.new()
	spawn.map				= inst.map
	spawn.type				= "Npc"
	spawn.nick				= "Xakelbael"
	spawn.id				= spawn.nick.hash()
	spawn.spawn_position	= Vector2i(1331, 1478)
	spawn.spawn_offset		= Vector2i(5, 5)
	spawn.direction			= ActorCommons.Direction.UP
	spawn.state				= ActorCommons.State.IDLE
	spawn.trigger_radius	= 120.0
	spawn.own_script		= "tonori/sandstorm/XakelbaelGlobal.gd"
	spawn.player_script		= "tonori/sandstorm/Xakelbael.gd"
	spawn.is_persistant		= false
	spawn.respawn_delay		= 0.0
	WorldAgent.CreateAgent(spawn, inst.id)
