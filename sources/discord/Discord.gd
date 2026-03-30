extends ServiceBase

# Discord bot instance
var bot : DiscordBot			= null
var regex : RegEx				= null

# Configuration
var botToken : String			= ""
var channelID : String			= ""
var enabled : bool				= false

# State
var isBotReady : bool			= false

# Constants
const IRCBridgePrefix : String	= "IRC-Bridge"
const IRCBridgeRegex : String	= r"^\*\*<(?<user>[^>]+)>\*\*\s*(?<msg>.+)$"

# Overrides
func _post_launch():
	isInitialized = true

func Destroy():
	if bot:
		bot.queue_free()
		bot = null

func _ready():
	enabled = Conf.GetBool("Discord", "Discord-Enabled", Conf.Type.CREDENTIAL)
	botToken = Conf.GetString("Discord", "Discord-Token", Conf.Type.CREDENTIAL)
	channelID = Conf.GetString("Discord", "Discord-ChannelID", Conf.Type.CREDENTIAL)

	if not enabled:
		Util.PrintInfo("Discord", "Discord bot disabled")
		return
	elif botToken.is_empty() or channelID.is_empty():
		Util.PrintInfo("Discord", "Discord bot not configured")
		return

	regex = RegEx.new()
	regex.compile(IRCBridgeRegex)

	bot = DiscordBot.new()
	bot.name = "DiscordBot"
	bot.TOKEN = botToken
	bot.VERBOSE = OS.is_debug_build()

	bot.bot_ready.connect(_on_bot_ready)
	bot.message_create.connect(_on_message_create)

	add_child(bot)
	bot.login()

	Util.PrintLog("Discord", "Discord bot initializing...")

# Signals
func _on_bot_ready(_bot : DiscordBot):
	if _bot != bot:
		return

	isBotReady = true
	Util.PrintLog("Discord", "Discord bot ready! Connected as %s" % bot.user.username)

func _on_message_create(_bot : DiscordBot, message : Message, _channel : Dictionary):
	if not isBotReady or _bot != bot or message.author.id == bot.user.id or message.channel_id != channelID or message.content.is_empty():
		return

	var username : String = message.author.username
	var content : String = message.content

	if username == IRCBridgePrefix:
		var result : RegExMatch = regex.search(content)
		if result:
			username = result.get_string("user")
			content = result.get_string("msg")

	Network.NotifyGlobal("ChatGlobal", [username, content])

# Utils
func SendToDiscord(playerName : String, messageText : String):
	if not isBotReady:
		return

	var formattedText : String = "**%s**: %s" % [playerName, messageText]
	bot.send(channelID, formattedText)
