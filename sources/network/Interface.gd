extends Node
class_name NetInterface

#
var multiplayerAPI : SceneMultiplayer				= MultiplayerAPI.create_default_interface()
var currentPeer : MultiplayerPeer					= null
var uniqueID : int									= NetworkCommons.RidDefault

var useWebSocket : bool								= false
var isOffline : bool								= false
var isLocal : bool									= false
var isTesting : bool								= false

#
func _init(_useWebSocket : bool, _isOffline : bool, _isLocal : bool, _isTesting : bool):
	useWebSocket	= _useWebSocket
	isOffline		= _isOffline
	isLocal			= _isLocal
	isTesting		= _isTesting

	multiplayerAPI.set_root_path(Launcher.Root.get_path())

	if useWebSocket:
		currentPeer = WebSocketMultiplayerPeer.new()
	else:
		currentPeer = ENetMultiplayerPeer.new()

	set_name("WebSocket" if useWebSocket else "ENet")
	Launcher.Root.add_child.call_deferred(self)

func _process(_delta: float):
	if multiplayerAPI.has_multiplayer_peer():
		multiplayerAPI.poll()

func Destroy():
	if currentPeer:
		currentPeer.close()
	uniqueID = NetworkCommons.RidDefault
	Launcher.Root.remove_child(self)
