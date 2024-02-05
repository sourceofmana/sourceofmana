extends Object
class_name NetworkCommons

# Server
static var ServerPort : int					= 6109
static var LocalServerAddress : String		= "127.0.0.1"
static var ServerAddress : String			= "75.119.128.234"
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
