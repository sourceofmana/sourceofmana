extends Node

#
func Configure(options : SentryOptions):
	options.godot_logger.event_mask = SentryOptions.MASK_ERROR | SentryOptions.MASK_WARNING | SentryOptions.MASK_SCRIPT | SentryOptions.MASK_SHADER
	options.debug = false
	options.attach_log = false
	options.before_send = BeforeSend

func BeforeSend(event : SentryEvent) -> SentryEvent:
	var enabled : bool = Conf.GetVariant("User", "Privacy-BugReports", Conf.Type.USERSETTINGS, true)
	return event if enabled else null

func SetPlayer(playerName : String):
	if SentrySDK.is_enabled() and not playerName.is_empty():
		var user : SentryUser = SentryUser.new()
		user.username = playerName
		SentrySDK.set_user(user)
		SentrySDK.set_tag("player", playerName)

func SetTransport(transport : Peers.TransportType):
	if SentrySDK.is_enabled():
		SentrySDK.set_tag("transport", Peers.TransportType.keys()[transport].to_lower())

#
func _enter_tree() -> void:
	SentrySDK.init(Configure)
	if SentrySDK.is_enabled():
		SentrySDK.set_tag("platform", OS.get_name())
		SentrySDK.set_tag("version", str(ProjectSettings.get_setting("application/config/version", "")))
		SentrySDK.set_tag("role", "server" if "--server" in OS.get_cmdline_args() else "client")
		SentrySDK.set_tag("headless", "true" if DisplayServer.get_name() == "headless" else "false")
