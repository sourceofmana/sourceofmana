extends Object
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

# Bulk
const BulkMinSize : int					= 3

# Navigation
const NavigationSpawnTry : int			= 10

# Guardband
const StartGuardbandDistSquared : float	= 6.0 * 6.0
const MaxGuardbandDistSquared : float	= 64.0 * 64.0

# Connection
const RidUnknown : int					= -2
const RidSingleMode : int				= -1
const RidDefault : int					= 0
const RidAuthority : int				= 1

const DelayInstant : int				= 0
const DelayShort : int					= 16
const DelayDefault : int				= 50
const DelayLogin : int					= 1000

const Timeout : int						= 1000
const TimeoutMin : int					= 30000
const TimeoutMax : int					= 60000

const LoginAttemptTimeout : float		= 15
const CharSelectionTimeout : float		= 15

# Peer
const UseENet : bool					= true
const UseWebSocket : bool				= true
const IsLocal : bool					= false
const IsTesting : bool					= true

const ServerKeyPath : String			= "user://server.key"
const ServerCertPath : String			= "user://server.crt"

# Auth
const PlayerNameMinSize : int			= 3
const PlayerNameMaxSize : int			= 30
const PasswordMinSize : int				= 6
const PasswordMaxSize : int				= 30
const EntryValidRegex : String			= "^[\\w#!@%&:;<>,\\$\\^*\\(\\)_+=\\{\\}\\[\\]\\.?/-]+$"
const EmailValidRegex : String			= "^[\\w\\.\\+\\-]+@[a-zA-Z0-9\\.\\-]+\\.[a-zA-Z]{2,}$"

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
	elif not CheckSize(passwordText, PasswordMinSize, PasswordMaxSize):
		return AuthError.ERR_PASSWORD_SIZE
	elif not CheckValid(nameText, EntryValidRegex):
		return AuthError.ERR_PASSWORD_VALID
	return AuthError.ERR_OK

static func CheckEmailInformation(emailText : String) -> AuthError:
	return AuthError.ERR_OK if CheckValid(emailText, EmailValidRegex) else AuthError.ERR_EMAIL_VALID

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
