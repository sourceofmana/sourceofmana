extends Node
class_name NetInterface

#
var multiplayerAPI : SceneMultiplayer				= MultiplayerAPI.create_default_interface()
var currentPeer : MultiplayerPeer					= null
var interfaceID : int								= NetworkCommons.PeerUnknownID

# Dictionary[Dictionary[StringName, Array[Array[...]]]]
var bulks : Dictionary[int, Dictionary]				= {}

var useWebSocket : bool								= false
var isOffline : bool								= false
var isLocal : bool									= false

#
func Bulk(methodName : StringName, args : Array, peerID : int):
	if methodName not in bulks[peerID]:
		bulks[peerID][methodName] = []
	bulks[peerID][methodName].append(args)

#
func _init(_useWebSocket : bool, _isOffline : bool, _isLocal : bool):
	useWebSocket	= _useWebSocket
	isOffline		= _isOffline
	isLocal			= _isLocal

	multiplayerAPI.set_root_path(Launcher.Root.get_path())

	if useWebSocket:
		currentPeer = WebSocketMultiplayerPeer.new()
		currentPeer.set_outbound_buffer_size(131071)
		currentPeer.set_inbound_buffer_size(131071)
		currentPeer.set_max_queued_packets(8192)

	else:
		currentPeer = ENetMultiplayerPeer.new()

	set_name("WebSocket" if useWebSocket else "ENet")
	Launcher.Root.add_child.call_deferred(self)

func _process(_delta: float):
	for peerID in bulks:
		var peerBulks : Dictionary = bulks[peerID]
		for methodName in peerBulks:
			var bulkedMethod : Array = peerBulks[methodName]
			var bulkedMethodSize : int = bulkedMethod.size()
			if bulkedMethodSize < NetworkCommons.BulkMinSize:
				for args in bulkedMethod:
					Network.callv(methodName, args + [peerID])
			else:
				Network.BulkCall.call(methodName, bulkedMethod, peerID)
			bulkedMethod.clear()

	if multiplayerAPI.has_multiplayer_peer():
		multiplayerAPI.poll()

func Destroy():
	if currentPeer:
		currentPeer.close()
	interfaceID = NetworkCommons.PeerUnknownID
	Launcher.Root.remove_child(self)
	queue_free()
