extends ServerTab

#
@onready var label : RichTextLabel			= $RichTextLabel

#
func Refresh():
	var lines : PackedStringArray = [
		"Uptime: %s" % Util.FormatPlayTime(floori(Time.get_ticks_msec() / 1000.0)),
		"Connected Peers: %d" % Peers.peers.size(),
		"Time FPS: %.1f" % Performance.get_monitor(Performance.TIME_FPS),
		"Time Process: %.3f ms" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0],
		"Time Physics Process: %.3f ms" % [Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0],
		"Time Navigation Process: %.3f ms" % Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS),
		"Memory Static: %.3f/%.3f MB" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1000000.0, Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1000000.0],
		"Memory Message Buffer: %.3f MB" % [Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX) / 1000000.0],
		"Object Count: %d" % int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"Object Resource Count: %d" % int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"Object Node Count: %d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"Object Orphan Node Count: %d" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"Render Total Objects: %d" % int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"Render Total Primitives: %d" % int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"Render Total Draw Calls: %d" % int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"Render Video Mem. Used: %.3f MB" % [Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1000000.0],
		"Render Texture Mem. Used: %.3f MB" % [Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1000000.0],
		"Render Buffer Mem. Used: %.3f MB" % [Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1000000.0],
		"Physics Active Objects: %d" % int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)),
		"Physics Collision Pairs: %d" % int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)),
		"Physics Island Count: %d" % int(Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT)),
		"Navigation Active Maps: %d" % int(Performance.get_monitor(Performance.NAVIGATION_ACTIVE_MAPS)),
		"Navigation Region Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_REGION_COUNT)),
		"Navigation Agent Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_AGENT_COUNT)),
		"Navigation Link Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_LINK_COUNT)),
		"Navigation Polygon Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_POLYGON_COUNT)),
		"Navigation Edge Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_COUNT)),
		"Navigation Edge Merge Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_MERGE_COUNT)),
		"Navigation Edge Connection Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_CONNECTION_COUNT)),
		"Navigation Edge Free Count: %d" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_FREE_COUNT)),
	]
	var text : String = "\n".join(lines)
	if label.text != text:
		label.text = text
