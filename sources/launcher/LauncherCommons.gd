extends Object
class_name LauncherCommons

# Project
const ProjectName : String				= "Source of Mana"
const SocialLink : String				= "https://discord.com/channels/581622549566193664/1013487216493854780"

# Map
static var DefaultStartMapID : int		= "Tulimshar".hash()
const DefaultStartPos : Vector2			= Vector2(1824, 2208)

# MapPool
const EnableMapPool : bool				= false
const MapPoolMaxSize : int				= 10

const ServerMaxFPS : int				= 30

# Common accessors
const IsTesting : bool					= true
static var isMobile : bool				= OS.has_feature("android") or OS.has_feature("ios") or Util.IsMobile()
static var isWeb : bool					= OS.has_feature("web")
