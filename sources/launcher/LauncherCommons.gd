extends RefCounted
class_name LauncherCommons

# Project
const ProjectName : String				= "Source of Mana"
const DiscordInviteLink : String		= "https://discord.com/invite/qR6ursz7xD"
const IRCLink : String					= "https://web.libera.chat/?channels=#sourceofmana"

# Map
static var DefaultStartMapID : int		= "Tulimshar".hash()
const DefaultStartPos : Vector2i		= Vector2i(2176, 2560) # Tile (68, 80)
const DefaultStartOffset : Vector2i		= Vector2i(64, 32)

static func GetRandomStartPos() -> Vector2i:
	return DefaultStartPos + Vector2i(randi_range(-DefaultStartOffset.x, DefaultStartOffset.x), randi_range(-DefaultStartOffset.y, DefaultStartOffset.y))

# MapPool
const EnableMapPool : bool				= false
const MapPoolMaxSize : int				= 10

const ServerMaxFPS : int				= 30

# Common accessors
static var IsTesting : bool				= not OS.has_feature("production")
static var isMobile : bool				= OS.has_feature("android") or OS.has_feature("ios") or Util.IsMobile()
static var isWeb : bool					= OS.has_feature("web")
