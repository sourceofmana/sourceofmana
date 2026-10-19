extends RefCounted
class_name ServerDeploy

#
const ExitInstalled : int					= 0
const ExitUpToDate : int					= 3
const RestartUnit : String					= "sourceofmana-deploy"

var thread : Thread							= null
var isRunning : bool						= false
var requesterPeerID : int					= NetworkCommons.PeerUnknownID

#
func Request(caller : PlayerAgent) -> bool:
	if Peers.GetPermission(caller.peerID) < ActorCommons.Permission.ADMIN:
		Network.CommandFeedback("Only admins can deploy", caller.peerID)
		return false

	var scriptPath : String = Conf.GetString("Deploy", "Deploy-Script", Conf.Type.CREDENTIAL)
	if scriptPath.is_empty():
		Network.CommandFeedback("Deploy-Script is not set in the server's credential.cfg", caller.peerID)
		return false

	if isRunning or Launcher.World.canary.isShuttingDown:
		Network.CommandFeedback("A deploy or restart is already in progress", caller.peerID)
		return false

	isRunning = true
	requesterPeerID = caller.peerID

	Util.PrintLog("Deploy", "%s requested a deploy" % caller.nick)
	Notify("Looking for a new build...")

	thread = Thread.new()
	thread.start(Install.bind(scriptPath), Thread.PRIORITY_LOW)
	return true

func Install(scriptPath : String):
	var output : Array = []
	var exitCode : int = OS.execute(scriptPath, ["install"], output, true)
	OnInstalled.call_deferred(scriptPath, exitCode, LastLine(output))

func OnInstalled(scriptPath : String, exitCode : int, summary : String):
	thread.wait_to_finish()
	thread = null
	Util.PrintLog("Deploy", "Install step exited with code %d: %s" % [exitCode, summary])

	match exitCode:
		ExitInstalled:
			Notify(summary)
			Countdown(scriptPath)
		ExitUpToDate:
			Notify(summary)
			isRunning = false
		_:
			Notify("Deploy failed (code %d): %s" % [exitCode, summary])
			isRunning = false

func Countdown(scriptPath : String):
	for step in ShutdownCanary.shutdownMessages.size():
		Launcher.World.commands.CommandBroadcast(null, ShutdownCanary.shutdownMessages[step])
		await Launcher.World.get_tree().create_timer(ShutdownCanary.shutdownDelays[step]).timeout

	Util.PrintLog("Deploy", "Countdown over, disconnecting %d peer(s) and restarting" % Peers.peers.size())
	ShutdownCanary.SetRefuseNewConnections(true)
	ShutdownCanary.DisconnectAllPeers()

	var pid : int = OS.create_process("systemd-run", ["--user", "--unit=" + RestartUnit, "--collect", scriptPath, "restart"])
	if pid <= 0:
		Util.PrintLog("Deploy", "Could not launch systemd-run: the new build will load on the next restart")
		ShutdownCanary.SetRefuseNewConnections(false)
		isRunning = false

#
func Notify(text : String):
	if Peers.GetPeer(requesterPeerID):
		Network.CommandFeedback(text, requesterPeerID)

static func LastLine(output : Array) -> String:
	var text : String = output[0] if not output.is_empty() else ""
	var lines : PackedStringArray = text.strip_edges().split("\n")
	var last : String = lines[lines.size() - 1].strip_edges()
	if last.begins_with("["):
		last = last.substr(last.find("]") + 1).strip_edges()
	return last.trim_prefix("ERROR: ")
