extends Object
class_name NetworkCommons

# Server
static var ServerPort : int					= 6109
static var LocalServerAddress : String		= "127.0.0.1"
static var ServerAddress : String			= "213.202.247.189"
static var MaxPlayerCount : int				= 32

# Navigation
static var NavigationSpawnTry : int			= 10

# Guardband
static var StartGuardbandDist : float		= 6.0
static var MaxGuardbandDist : float			= 64.0
static var PatchGuardband : float			= 100.0

# Connection
static var RidUnknown : int					= -2
static var RidSingleMode : int				= -1
static var RidDefault : int					= 0

static var DelayInstant : int				= 0
static var DelayDefault : int				= 50

static var Timeout : int					= 1000
static var TimeoutMin : int					= 30000
static var TimeoutMax : int					= 60000

# Auth
static var PlayerNameMinSize : int			= 3
static var PlayerNameMaxSize : int			= 30
static var PlayerNameInvalidChar : String	= "[^\\w\\h]+"

# Peer
static var EnableWebSocket : bool			= true
static var ClientTrustedCAPath : String		= "res://publishing/my_trusted_cas.crt"
static var ServerKeyPath : String			= "res://publishing/private_key.key"
static var ServerCertsPath : String			= "res://publishing/my_server_cas.crt"
