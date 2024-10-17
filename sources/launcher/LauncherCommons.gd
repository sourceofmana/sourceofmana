extends Object
class_name LauncherCommons

# Project
const ProjectName : String				= "Source of Mana"
const SocialLink : String				= "https://discord.com/channels/581622549566193664/1013487216493854780"

# Map
const DefaultStartMap : String			= "Splatyna Cave Entrance"
const DefaultStartPos : Vector2			= Vector2(1456, 1504)

# MapPool
const EnableMapPool : bool				= false
const MapPoolMaxSize : int				= 10

#
static var isMobile : bool				= OS.get_name() == "Android" or OS.get_name() == "iOS"
