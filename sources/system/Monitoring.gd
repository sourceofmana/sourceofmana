extends Node
class_name Monitoring

#
static func IsEnabled() -> bool:
	return Conf.GetUserValue("Privacy-BugReports", false)

static func Configure(options : SentryOptions):
	options.godot_logger.event_mask = SentryOptions.MASK_ERROR | SentryOptions.MASK_WARNING | SentryOptions.MASK_SCRIPT | SentryOptions.MASK_SHADER
	options.debug = false
	options.attach_log = false
	options.before_send = BeforeSend

static func BeforeSend(event : SentryEvent) -> SentryEvent:
	return event if IsEnabled() else null

static func SetPlayer(playerName : String):
	if SentrySDK.is_enabled() and not playerName.is_empty():
		var user : SentryUser = SentryUser.new()
		user.username = playerName
		SentrySDK.set_user(user)
		SentrySDK.set_tag("player", playerName)

static func SetTransport(transport : Peers.TransportType):
	if SentrySDK.is_enabled():
		SentrySDK.set_tag("transport", Peers.TransportType.keys()[transport].to_lower())

#
static func Init():
	if not OS.has_feature("sentry"):
		return
	if not IsEnabled():
		return

	SentrySDK.init(Configure)
	if SentrySDK.is_enabled():
		SentrySDK.set_tag("platform", OS.get_name())
		SentrySDK.set_tag("version", str(ProjectSettings.get_setting("application/config/version", "")))
		SentrySDK.set_tag("role", "server" if "--server" in OS.get_cmdline_args() else "client")
		SentrySDK.set_tag("headless", "true" if DisplayServer.get_name() == "headless" else "false")
