extends Control

#
@onready var infoLabel : RichTextLabel					= $HSections/Info/VBox/ScrollContainer/RichTextLabel
@onready var peersLabel : RichTextLabel					= $HSections/Peers/RichTextLabel
var timer : Timer										= null

#
func _on_info_update():
	infoLabel.clear()
	infoLabel.add_text("Time FPS: %.1f\n" % Performance.get_monitor(Performance.TIME_FPS))
	infoLabel.add_text("Time Process: %.3f ms\n" % [Performance.get_monitor(Performance.TIME_PROCESS)*1000.0])
	infoLabel.add_text("Time Physics Process: %.3f ms\n" % [Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0])
	infoLabel.add_text("Time Navigation Process: %.3f ms\n" % Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS))
	infoLabel.add_text("Memory Static: %.3f/%.3f MB\n" % [Performance.get_monitor(Performance.MEMORY_STATIC)/1000000.0, Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1000000.0])
	infoLabel.add_text("Memory Message Buffer: %.3f MB\n" % [Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX)/1000000.0])
	infoLabel.add_text("Object Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	infoLabel.add_text("Object Resource Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
	infoLabel.add_text("Object Node Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	infoLabel.add_text("Object Orphan Node Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	infoLabel.add_text("Render Total Objects: %d\n" % int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	infoLabel.add_text("Render Total Primitives: %d\n" % int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	infoLabel.add_text("Render Total Draw Calls: %d\n" % int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	infoLabel.add_text("Render Video Mem. Used: %.3f MB\n" % [Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1000000.0])
	infoLabel.add_text("Render Texture Mem. Used: %.3f MB\n" % [Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1000000.0])
	infoLabel.add_text("Render Buffer Mem. Used: %.3f MB\n" % [Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)/1000000.0])
	infoLabel.add_text("Physics Active Objects: %d\n" % int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)))
	infoLabel.add_text("Physics Collision Pairs: %d\n" % int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)))
	infoLabel.add_text("Physics Island Count: %d\n" % int(Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT)))
	infoLabel.add_text("Navigation Active Maps: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_ACTIVE_MAPS)))
	infoLabel.add_text("Navigation Region Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_REGION_COUNT)))
	infoLabel.add_text("Navigation Agent Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_AGENT_COUNT)))
	infoLabel.add_text("Navigation Link Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_LINK_COUNT)))
	infoLabel.add_text("Navigation Polygon Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_POLYGON_COUNT)))
	infoLabel.add_text("Navigation Edge Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_COUNT)))
	infoLabel.add_text("Navigation Edge Merge Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_MERGE_COUNT)))
	infoLabel.add_text("Navigation Edge Connection Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_CONNECTION_COUNT)))
	infoLabel.add_text("Navigation Edge Free Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_FREE_COUNT)))

func _on_peer_connection_update():
	peersLabel.text = ""
	for peerID in Peers.peers:
		var peer : Peers.Peer = Peers.GetPeer(peerID)
		var player : PlayerAgent = Peers.GetAgent(peerID)
		var playerNickname : String = player.nick if player else "-1"
		peersLabel.add_text("RPC: %d\t\tAccount: %d\t\tCharacter: %d\t\tAgent: %s [%d]\t\tMode: %s\n" % [peerID, peer.accountID, peer.characterID, playerNickname, peer.agentRID, "WebSocket" if peer.usingWebSocket else "ENet"])

#
func _ready():
	Network.peer_update.connect(_on_peer_connection_update)
	Network.online_accounts_update.connect(_on_peer_connection_update)
	Network.online_characters_update.connect(_on_peer_connection_update)
	Network.online_agents_update.connect(_on_peer_connection_update)

	if NetworkCommons.IsLocal:
		timer = Timer.new()
		timer.set_name("ServerTimer")
		add_child(timer)
		Callback.StartTimer(timer, 3, _on_info_update)
		_on_info_update()
