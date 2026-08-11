extends Node
class_name NetInterface

#
var multiplayerAPI : SceneMultiplayer				= MultiplayerAPI.create_default_interface()
var currentPeer : MultiplayerPeer					= null
var interfaceID : int								= NetworkCommons.PeerUnknownID

# Dictionary[Dictionary[StringName, Array[Array[...]]]]
var bulks : Dictionary[int, Dictionary]				= {}

var useWebSocket : bool								= false
var useWebRTC : bool								= false
var isOffline : bool								= false
var isLocal : bool									= false

var rtcConnections : Dictionary[int, WebRTCPeerConnection]	= {}
var rtcIceServers : Array[Dictionary]				= NetworkCommons.IceServers

#
func Bulk(methodName : StringName, args : Array, peerID : int):
	if methodName not in bulks[peerID]:
		bulks[peerID][methodName] = []
	bulks[peerID][methodName].append(args)

#
func _init(_useWebSocket : bool, _useWebRTC : bool, _isOffline : bool, _isLocal : bool):
	useWebSocket	= _useWebSocket
	useWebRTC		= _useWebRTC
	isOffline		= _isOffline
	isLocal			= _isLocal

	multiplayerAPI.set_root_path(Launcher.Root.get_path())

	if useWebRTC:
		currentPeer = WebRTCMultiplayerPeer.new()

	elif useWebSocket:
		currentPeer = WebSocketMultiplayerPeer.new()
		currentPeer.set_outbound_buffer_size(131071)
		currentPeer.set_inbound_buffer_size(131071)
		currentPeer.set_max_queued_packets(8192)

	else:
		currentPeer = ENetMultiplayerPeer.new()

	set_name("WebRTC" if useWebRTC else ("WebSocket" if useWebSocket else "ENet"))
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
		peerBulks.clear()

	if multiplayerAPI.has_multiplayer_peer():
		multiplayerAPI.poll()

# WebRTC signaling
func RtcMultiplayerPeer() -> WebRTCMultiplayerPeer:
	return currentPeer as WebRTCMultiplayerPeer

func CreateRtcConnection(remotePeerID : int) -> WebRTCPeerConnection:
	var connection : WebRTCPeerConnection = WebRTCPeerConnection.new()
	connection.initialize({ "iceServers" : rtcIceServers })
	connection.session_description_created.connect(_OnRtcSessionCreated.bind(remotePeerID))
	connection.ice_candidate_created.connect(_OnRtcIceCandidate.bind(remotePeerID))
	rtcConnections[remotePeerID] = connection
	RtcMultiplayerPeer().add_peer(connection, remotePeerID)
	return connection

func AddRtcIceCandidate(remotePeerID : int, media : String, index : int, candidateName : String):
	var connection : WebRTCPeerConnection = rtcConnections.get(remotePeerID, null)
	if connection:
		connection.add_ice_candidate(media, index, candidateName)

func RemoveRtcConnection(remotePeerID : int):
	if remotePeerID in rtcConnections:
		rtcConnections.erase(remotePeerID)
		var rtcPeer : WebRTCMultiplayerPeer = RtcMultiplayerPeer()
		if rtcPeer and rtcPeer.has_peer(remotePeerID):
			rtcPeer.remove_peer(remotePeerID)

func _OnRtcSessionCreated(type : String, sdp : String, remotePeerID : int):
	var connection : WebRTCPeerConnection = rtcConnections.get(remotePeerID, null)
	if connection:
		connection.set_local_description(type, sdp)
		if type == "offer":
			Network.RtcOffer(sdp, remotePeerID)
		else:
			Network.RtcAnswer(sdp, remotePeerID)

func _OnRtcIceCandidate(media : String, index : int, candidateName : String, remotePeerID : int):
	if self is NetServer:
		Network.RtcCandidateToClient(media, index, candidateName, remotePeerID)
	else:
		Network.RtcCandidateToServer(media, index, candidateName, remotePeerID)

func Destroy():
	if currentPeer:
		currentPeer.close()
	interfaceID = NetworkCommons.PeerUnknownID
	Launcher.Root.remove_child(self)
	queue_free()
