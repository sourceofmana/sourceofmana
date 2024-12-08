extends Control

#
@onready var InfoLabel : RichTextLabel					= $HSections/Info/VBox/RichTextLabel
@onready var PeersLabel : RichTextLabel					= $HSections/Peers/RichTextLabel

#
func _on_info_update():
	InfoLabel.add_text("Time FPS: %.1f\n" % Performance.get_monitor(Performance.TIME_FPS))
	InfoLabel.add_text("Time Process: %.3f\n" % Performance.get_monitor(Performance.TIME_PROCESS))
	InfoLabel.add_text("Time Physics Process: %.3f\n" % Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
	InfoLabel.add_text("Time Navigation Process: %.3f\n" % Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS))
	InfoLabel.add_text("Memory Static: %.3f/%.3f MB\n" % [Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1000.0, Performance.get_monitor(Performance.MEMORY_STATIC)/1000.0])
	InfoLabel.add_text("Memory Message Buffer: %.3f MB\n" % [Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX)/1000.0])
	InfoLabel.add_text("Object Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	InfoLabel.add_text("Object Resource Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
	InfoLabel.add_text("Object Node Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	InfoLabel.add_text("Object Orphan Node Count: %d\n" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	InfoLabel.add_text("Render Total Objects: %d\n" % int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	InfoLabel.add_text("Render Total Primitives: %d\n" % int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	InfoLabel.add_text("Render Total Draw Calls: %d\n" % int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	InfoLabel.add_text("Render Video Mem. Used: %.3f MB\n" % [Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1000.0])
	InfoLabel.add_text("Render Texture Mem. Used: %.3f MB\n" % [Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1000.0])
	InfoLabel.add_text("Render Buffer Mem. Used: %.3f MB\n" % [Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)/1000.0])
	InfoLabel.add_text("Physics Active Objects: %d\n" % int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)))
	InfoLabel.add_text("Physics Collision Pairs: %d\n" % int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)))
	InfoLabel.add_text("Physics Island Count: %d\n" % int(Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT)))
	InfoLabel.add_text("Navigation Active Maps: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_ACTIVE_MAPS)))
	InfoLabel.add_text("Navigation Region Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_REGION_COUNT)))
	InfoLabel.add_text("Navigation Agent Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_AGENT_COUNT)))
	InfoLabel.add_text("Navigation Link Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_LINK_COUNT)))
	InfoLabel.add_text("Navigation Polygon Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_POLYGON_COUNT)))
	InfoLabel.add_text("Navigation Edge Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_COUNT)))
	InfoLabel.add_text("Navigation Edge Merge Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_MERGE_COUNT)))
	InfoLabel.add_text("Navigation Edge Connection Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_CONNECTION_COUNT)))
	InfoLabel.add_text("Navigation Edge Free Count: %d\n" % int(Performance.get_monitor(Performance.NAVIGATION_EDGE_FREE_COUNT)))

func _on_peer_connection_update():
	PeersLabel.text = ""
	for rpcID in Peers.peers:
		var peer : Peers.Peer = Peers.GetPeer(rpcID)
		var player : PlayerAgent = Peers.GetAgent(rpcID)
		var playerNickname : String = player.nick if player else "-1"
		PeersLabel.add_text("RPC: %d\t\tAccount: %d\t\tCharacter: %d\t\tAgent: %s [%d] \n" % [rpcID, peer.accountRID, peer.characterRID, playerNickname, peer.agentRID])

#
func _ready():
	if Network.Server:
		Network.Server.peer_update.connect(_on_peer_connection_update)
		Network.Server.online_accounts_update.connect(_on_peer_connection_update)
		Network.Server.online_characters_update.connect(_on_peer_connection_update)
		Network.Server.online_agents_update.connect(_on_peer_connection_update)
