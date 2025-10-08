class_name WorldInstance
extends SubViewport

#
var id : int							= 0
var npcs : Array[AIAgent]				= []
var mobs : Array[AIAgent]				= []
var players : Array[BaseAgent]			= []
var drops : Dictionary[int, Drop]		= {}
var map : WorldMap						= null
var timers : Node						= Node.new()

#
func _ready():
	timers.set_name("Timers")
	add_child.call_deferred(timers)
	timers.tree_entered.connect(CheckIterationID)


func CheckIterationID():
	var iterationDone : bool = true
	var mapRID : RID = get_world_2d().get_navigation_map()
	if not NavigationServer2D.map_get_iteration_id(mapRID):
		iterationDone = false
	else:
		for regionRID in NavigationServer2D.map_get_regions(mapRID):
			if not NavigationServer2D.region_get_iteration_id(regionRID):
				iterationDone = false
				break

	if not iterationDone:
		# Wait 0.5s if the navigation server is busy instancing other regions in other threads
		Callback.SelfDestructTimer(timers, 0.5, CheckIterationID, [])
	else:
		_map_loaded()

func _map_loaded():
	for spawn in map.spawns:
		if spawn:
			for i in spawn.count:
				WorldAgent.CreateAgent(spawn, id, spawn.nick)
	RefreshProcessMode()

#
static func Create(_map : WorldMap, instanceID : int = 0) -> WorldInstance:
	assert(_map != null, "Could not create an instance on a non-valid map")
	if _map == null:
		return

	var inst : WorldInstance = WorldInstance.new()
	inst.id = instanceID
	inst.map = _map
	inst.name = _map.name + "_" + str(instanceID)

	WorldNavigation.CreateInstance(_map, inst.get_world_2d().get_navigation_map())
	Launcher.Root.add_child.call_deferred(inst)

	return inst

func Destroy():
	for player in players:
		WorldAgent.RemoveAgent(player)
	for mob in mobs:
		WorldAgent.RemoveAgent(mob)
	for npc in npcs:
		WorldAgent.RemoveAgent(npc)
	Launcher.Root.remove_child(self)

#
func QueryProcessMode(delaySec : float = ActorCommons.MapProcessingToggleDelay):
	Callback.SelfDestructTimer(Launcher, delaySec, RefreshProcessMode, [], "ProcessMode_" + name)

func RefreshProcessMode():
	if players.size() == 0 and timers.get_child_count() > 0:
		QueryProcessMode(ActorCommons.MapProcessingToggleExtraDelay)
	else:
		var toggle : bool= players.size() == 0
		set_process_mode(ProcessMode.PROCESS_MODE_DISABLED if toggle else ProcessMode.PROCESS_MODE_INHERIT)
		for npc in npcs:
			if npc.aiTimer:
				npc.aiTimer.set_paused(toggle)
			if npc.actionTimer:
				npc.actionTimer.set_paused(toggle)
		for mob in mobs:
			if mob.aiTimer:
				mob.aiTimer.set_paused(toggle)
			if mob.actionTimer:
				mob.actionTimer.set_paused(toggle)
