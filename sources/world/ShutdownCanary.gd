extends RefCounted
class_name ShutdownCanary

#
const checkInternalSec : float = 5.0
const shutdownMessages : PackedStringArray = [
	"Server restarting in 30 seconds.",
	"Server restarting in 15 seconds.",
]
const shutdownDelays : PackedFloat32Array = [
	30.0,
	15.0,
]

var timer : Timer = null
var isShuttingDown : bool = false
var shuttingDownStep : int = 0

#
func Start() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://canary"))
	timer = Timer.new()
	timer.wait_time = checkInternalSec
	timer.autostart = true
	timer.timeout.connect(CheckCanary)
	Launcher.World.add_child(timer)

func CheckCanary() -> void:
	if FileAccess.file_exists(Path.CanaryFile):
		isShuttingDown = true
		for server in [Network.ENetServer, Network.WebSocketServer, Network.WebRTCServer]:
			if server and server.currentPeer:
				server.currentPeer.refuse_new_connections = true
		shuttingDownStep = 0
		timer.timeout.disconnect(CheckCanary)
		timer.one_shot = true
		timer.timeout.connect(OnShutdownStep)
		ShutdownStep()

func ShutdownStep() -> void:
	Launcher.World.commands.CommandBroadcast(null, shutdownMessages[shuttingDownStep])
	timer.wait_time = shutdownDelays[shuttingDownStep]
	shuttingDownStep += 1
	timer.start()

func OnShutdownStep() -> void:
	if shuttingDownStep < shutdownMessages.size():
		ShutdownStep()
	else:
		for peerID in Peers.peers.keys():
			var server : NetServer = Peers.GetAssociatedNetServer(peerID)
			if server:
				server.multiplayerAPI.disconnect_peer(peerID)
				server.DisconnectPeer(peerID)
		Launcher.Quit()
