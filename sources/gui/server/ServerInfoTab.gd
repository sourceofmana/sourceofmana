extends ServerTableTab

#
const Header : PackedStringArray			= ["Name", "Value"]

#
func CanRefresh() -> bool:
	return true

func FillSection(title : String, rows : Array):
	FillTable(title, Header, rows).SetColumnColor(1, UICommons.LightTextColor)

func Refresh():
	FillSection("General", [
		["Uptime", Util.FormatPlayTime(floori(Time.get_ticks_msec() / 1000.0))],
		["Connected Peers", Peers.peers.size()],
	])
	FillSection("Time", [
		["FPS", "%.1f" % Performance.get_monitor(Performance.TIME_FPS)],
		["Process", "%.3f ms" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0]],
		["Physics Process", "%.3f ms" % [Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0]],
		["Navigation Process", "%.3f ms" % Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS)],
	])
	FillSection("Memory", [
		["Static", "%.3f/%.3f MB" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1000000.0, Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1000000.0]],
		["Message Buffer", "%.3f MB" % [Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX) / 1000000.0]],
	])
	FillSection("Objects", [
		["Objects", int(Performance.get_monitor(Performance.OBJECT_COUNT))],
		["Resources", int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))],
		["Nodes", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))],
		["Orphan Nodes", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))],
	])
	FillSection("Render", [
		["Total Objects", int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))],
		["Total Primitives", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))],
		["Total Draw Calls", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))],
		["Video Mem. Used", "%.3f MB" % [Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1000000.0]],
		["Texture Mem. Used", "%.3f MB" % [Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1000000.0]],
		["Buffer Mem. Used", "%.3f MB" % [Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1000000.0]],
	])
	FillSection("Physics", [
		["Active Objects", int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS))],
		["Collision Pairs", int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS))],
		["Island Count", int(Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT))],
	])
	FillSection("Navigation", [
		["Active Maps", int(Performance.get_monitor(Performance.NAVIGATION_ACTIVE_MAPS))],
		["Regions", int(Performance.get_monitor(Performance.NAVIGATION_REGION_COUNT))],
		["Agents", int(Performance.get_monitor(Performance.NAVIGATION_AGENT_COUNT))],
		["Links", int(Performance.get_monitor(Performance.NAVIGATION_LINK_COUNT))],
		["Polygons", int(Performance.get_monitor(Performance.NAVIGATION_POLYGON_COUNT))],
		["Edges", int(Performance.get_monitor(Performance.NAVIGATION_EDGE_COUNT))],
		["Edge Merges", int(Performance.get_monitor(Performance.NAVIGATION_EDGE_MERGE_COUNT))],
		["Edge Connections", int(Performance.get_monitor(Performance.NAVIGATION_EDGE_CONNECTION_COUNT))],
		["Free Edges", int(Performance.get_monitor(Performance.NAVIGATION_EDGE_FREE_COUNT))],
	])

#
func _init():
	super._init()
	refreshTicks = 1
