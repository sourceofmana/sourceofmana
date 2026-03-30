extends RefCounted
class_name NetworkCommons

# Server
const WebSocketPortTesting : int		= 6118
const ENetPortTesting : int				= 6119
const ServerAddressTesting : String		= "som.manasource.org"

const WebSocketPort : int				= 6108
const ENetPort : int					= 6109
const ServerAddress : String			= "som.manasource.org"

const LocalServerAddress : String		= "127.0.0.1"
const MaxPlayerCount : int				= 128

# Visibility
const VisibilityBorder : float			= 64.0
const MaxVisibilityHalfWidth : float	= 2560 / 2.0
const MaxVisibilityHalfHeight : float	= 1440 / 2.0

static func IsAlwaysVisible(agent : BaseAgent):
	return agent and agent is AIAgent and agent.spawnInfo and agent.spawnInfo.is_always_visible

static func IsVisible(fromPos : Vector2, toPos : Vector2, halfSize : Vector2) -> bool:
	var diff : Vector2 = (toPos - fromPos).abs()
	return diff.x <= halfSize.x and diff.y <= halfSize.y

# Bulk
const BulkMinSize : int					= 3

# Navigation
const NavigationSpawnTry : int			= 10

# Guardband
const StartGuardbandDistSquared : float	= 6.0 * 6.0
const MaxGuardbandDistSquared : float	= 64.0 * 64.0

# Connection
const PeerUnknownID : int				= -2
const PeerOfflineID : int				= -1
const PeerAuthorityID : int				= 1

const DelayInstant : int				= 0
const DelayShort : int					= 16
const DelayDefault : int				= 50
const DelayLogin : int					= 1000

const Timeout : int						= 1000
const TimeoutMin : int					= 30000
const TimeoutMax : int					= 60000

const LoginAttemptTimeout : float		= 15
const CharSelectionTimeout : float		= 15

# Protocol
static var ProtocolVersion : int		= 0

static func ComputeProtocolVersion(network : Node) -> int:
	var rpcConfig : Dictionary = network.get_script().get_rpc_config()
	var methods : Array = rpcConfig.keys()
	methods.sort()

	var serialized : String = ""
	for method in methods:
		var config : Dictionary = rpcConfig[method]
		var keys : Array = config.keys()
		keys.sort()

		serialized += method
		for key in keys:
			serialized += ",%s:%s" % [key, config[key]]
		serialized += "\n"

	return hash(serialized)

# Peer
const UseENet : bool					= true
const UseWebSocket : bool				= true
const IsLocal : bool					= false

const ServerKeyPath : String			= "user://server.key"
const ServerCertPath : String			= "user://server.crt"

# Auth
const PlayerNameMinSize : int			= 3
const PlayerNameMaxSize : int			= 30
const PasswordMinSize : int				= 6
const PasswordMaxSize : int				= 30
const EntryValidRegex : String			= "^[\\w#!@%&:;<>,\\$\\^*\\(\\)_+=\\{\\}\\[\\]\\.?/-]+$"
const EmailValidRegex : String			= "^[\\w\\.\\+\\-]+@[a-zA-Z0-9\\.\\-]+\\.[a-zA-Z]{2,}$"

# Token
const TokenExpirySec : int				= 30 * 24 * 60 * 60

# Password Reset
const ResetCodeExpiryMinutes : int		= 15
const ResetCodeCooldownMinutes : int	= 5
const ResetCodeSize : int				= 6

# Tools
const OnlineListPath : String			= ""

enum AuthError {
	ERR_OK = 0,
	ERR_NO_PEER_DATA,
	ERR_TIMEOUT,
	ERR_SERVER_UNREACHABLE,
	ERR_RPC_MISMATCH,
	ERR_AUTH,
	ERR_PASSWORD_VALID,
	ERR_PASSWORD_SIZE,
	ERR_NAME_AVAILABLE,
	ERR_NAME_VALID,
	ERR_NAME_SIZE,
	ERR_EMAIL_VALID,
	ERR_DUPLICATE_CONNECTION,
	ERR_BANNED,
	ERR_TOKEN,
	ERR_RESET_UNAVAILABLE,
	ERR_RESET_EMAIL_SENT,
	ERR_RESET_INVALID_CODE,
	ERR_RESET_PASSWORD_UPDATED,
	ERR_PASSWORD_MISMATCH,
	ERR_PASSWORD_CHANGE_OK,
	ERR_PASSWORD_CHANGE_WRONG,
}

static func CheckSize(entry : String, minSize : int, maxSize : int) -> bool:
	var currentSize : int = entry.length()
	return (currentSize >= minSize and currentSize <= maxSize)

static func CheckValid(entry : String, validRegex : String) -> bool:
	var regex = RegEx.new()
	regex.compile(validRegex)
	var result = regex.search(entry)
	return result != null

static func CheckAuthInformation(nameText : String, passwordText : String) -> AuthError:
	if not CheckSize(nameText, PlayerNameMinSize, PlayerNameMaxSize):
		return AuthError.ERR_NAME_SIZE
	elif not CheckValid(nameText, EntryValidRegex):
		return AuthError.ERR_NAME_VALID
	return CheckPasswordInformation(passwordText)

static func CheckPasswordInformation(passwordText : String) -> AuthError:
	if not CheckSize(passwordText, PasswordMinSize, PasswordMaxSize):
		return AuthError.ERR_PASSWORD_SIZE
	elif not CheckValid(passwordText, EntryValidRegex):
		return AuthError.ERR_PASSWORD_VALID
	return AuthError.ERR_OK

static func CheckEmailInformation(emailText : String) -> AuthError:
	return AuthError.ERR_OK if CheckValid(emailText, EmailValidRegex) else AuthError.ERR_EMAIL_VALID

static func CheckResetCode(code : String) -> bool:
	return code.length() == ResetCodeSize and code.is_valid_int()

# Character
enum CharacterError {
	ERR_OK = 0,
	ERR_ALREADY_LOGGED_IN,
	ERR_NO_PEER_DATA,
	ERR_NO_CHARACTER_ID,
	ERR_NO_ACCOUNT_ID,
	ERR_TIMEOUT,
	ERR_MISSING_PARAMS,
	ERR_NAME_AVAILABLE,
	ERR_NAME_VALID,
	ERR_NAME_SIZE,
	ERR_SLOT_AVAILABLE,
	ERR_EMPTY_ACCOUNT,
}

static func CheckCharacterInformation(nickText : String) -> CharacterError:
	if not CheckSize(nickText, PlayerNameMinSize, PlayerNameMaxSize):
		return CharacterError.ERR_NAME_SIZE
	elif not CheckValid(nickText, EntryValidRegex):
		return CharacterError.ERR_NAME_VALID
	return CharacterError.ERR_OK
