class_name WorldInstance
extends SubViewport

#
var id : int							= 0
var npcs : Array[BaseAgent]				= []
var mobs : Array[BaseAgent]				= []
var players : Array[BaseAgent]			= []
var drops : Dictionary					= {}
var map : WorldMap						= null

#
func _ready():
	for spawn in map.spawns:
		if spawn and Instantiate.FindEntityReference(spawn.name) != null:
			for i in spawn.count:
				WorldAgent.CreateAgent(spawn, id)

#
static func Create(_map : WorldMap, instanceID : int = 0) -> WorldInstance:
	Util.Assert(_map != null, "Could not create an instance on a non-valid map")
	if _map == null:
		return

	var inst : WorldInstance = WorldInstance.new()
	inst.id = instanceID
	inst.map = _map
	inst.name = _map.name + "_" + str(instanceID)
	inst.RefreshProcessMode()

	WorldNavigation.CreateInstance(_map, inst.get_world_2d().get_navigation_map())
	Launcher.Root.add_child.call_deferred(inst)

	return inst

#
func QueryProcessMode():
	Callback.SelfDestructTimer(Launcher, 10, RefreshProcessMode, [], "ProcessMode_" + name)

func RefreshProcessMode():
	set_process_mode(ProcessMode.PROCESS_MODE_DISABLED if players.size() == 0 else ProcessMode.PROCESS_MODE_INHERIT)
