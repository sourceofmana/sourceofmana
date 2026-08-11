extends FileData
class_name MapData

@export var serverData : MapServerData		= null
@export var layersPath : String				= ""
@export var navigation : NavigationPolygon	= null
@export var minimapPath : String			= ""

func StripClient():
	layersPath = ""
	minimapPath = ""

func StripServer():
	serverData = null
	navigation = null
