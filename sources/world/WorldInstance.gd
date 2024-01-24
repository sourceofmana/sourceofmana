class_name WorldInstance
extends SubViewport

#
var id : int							= 0
var npcs : Array[BaseAgent]				= []
var mobs : Array[BaseAgent]				= []
var players : Array[BaseAgent]			= []
var map : WorldService.Map				= null

#
func _init():
	disable_3d = true
	gui_disable_input = true
	set_process_mode(ProcessMode.PROCESS_MODE_DISABLED)

func _ready():
	Util.Assert(map != null, "No map associated to this ghost instance, should never happen")
	name = map.name + "_" + str(id)
	RefreshProcessMode()

#
func QueryProcessMode():
	Util.SelfDestructTimer(Launcher, 10, RefreshProcessMode, "ProcessMode_" + name)

func RefreshProcessMode():
	set_process_mode(ProcessMode.PROCESS_MODE_DISABLED if players.size() == 0 else ProcessMode.PROCESS_MODE_INHERIT)
