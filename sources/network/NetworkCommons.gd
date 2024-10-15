extends Object
class_name NetworkCommons

# Server
const ServerPort : int					= 6109
const LocalServerAddress : String		= "127.0.0.1"
const ServerAddress : String			= "som.manasource.org"
const MaxPlayerCount : int				= 32

# Navigation
const NavigationSpawnTry : int			= 10

# Guardband
const StartGuardbandDistSquared : float	= 6.0 * 6.0
const MaxGuardbandDistSquared : float	= 64.0 * 64.0

# Connection
const RidUnknown : int					= -2
const RidSingleMode : int				= -1
const RidDefault : int					= 0

const DelayInstant : int				= 0
const DelayDefault : int				= 50

const Timeout : int						= 1000
const TimeoutMin : int					= 30000
const TimeoutMax : int					= 60000

const LoginAttemptTimeout : float		= 15
const CharSelectionTimeout : float		= 15

# Auth
const PlayerNameMinSize : int			= 3
const PlayerNameMaxSize : int			= 30
const PlayerNameInvalidChar : String	= "[^\\w\\h]+"

# Peer
const EnableWebSocket : bool			= false
const ClientTrustedCAPath : String		= "res://publishing/my_trusted_cas.crt"
const ServerKeyPath : String			= "res://publishing/private_key.key"
const ServerCertsPath : String			= "res://publishing/my_server_cas.crt"
