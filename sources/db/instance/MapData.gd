extends FileData
class_name MapData

@export var serverData : MapServerData		= null
@export var layersPath : String				= ""
@export var navigation : NavigationPolygon	= null
@export var minimapPath : String			= ""
@export var flags : WorldMap.Flags			= WorldMap.Flags.NONE

func HasFlags(checkedFlags : WorldMap.Flags) -> bool:
	return !!(flags & checkedFlags)

func StripClient():
	layersPath = ""
	minimapPath = ""

func StripServer():
	serverData = null
	navigation = null
