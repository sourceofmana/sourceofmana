extends ServiceBase

#
enum Type
{
	NONE = -1,
	PROJECT = 0,
	MAP,
	WINDOW,
	GAMEPLAY,
	NETWORK,
	AUTH,
	DEBUG,
	COUNT
}

var confFiles : Array		= []
var cache : Dictionary		= {}

#
func GetVariant(category : String, param : String, type : Type, default):
	var value = default
	var cacheID = "%s%s%d" % [category, param, type]

	if cacheID in cache:
		value = cache[cacheID]
	elif type < Type.COUNT and confFiles[type].has_section_key(category, param):
		value = confFiles[type].get_value(category, param, default)
		cache[cacheID] = value 
	else:
		Util.Assert(false, "Can't find %s within our loaded conf files" % [cacheID])

	return value

func GetBool(category : String, param : String, type : Type = Type.NONE) -> bool:
	return GetVariant(category, param, type, false)

func GetInt(category : String, param : String, type : Type = Type.NONE) -> int:
	return GetVariant(category, param, type, 0)

func GetFloat(category : String, param : String, type : Type = Type.NONE) -> float:
	return GetVariant(category, param, type, 0.0)

func GetVector2(category : String, param : String, type : Type = Type.NONE) -> Vector2:
	return GetVariant(category, param, type, Vector2.ZERO)

func GetVector2i(category : String, param : String, type : Type = Type.NONE) -> Vector2i:
	return GetVariant(category, param, type, Vector2i.ZERO)

func GetString(category : String, param : String, type : Type = Type.NONE) -> String:
	return GetVariant(category, param, type, "")

#
func _init():
	notification(NOTIFICATION_READY) 

func _ready():
	confFiles.append(FileSystem.LoadConfig("project"))
	confFiles.append(FileSystem.LoadConfig("map"))
	confFiles.append(FileSystem.LoadConfig("window"))
	confFiles.append(FileSystem.LoadConfig("gameplay"))
	confFiles.append(FileSystem.LoadConfig("network"))
	confFiles.append(FileSystem.LoadConfig("auth"))
	confFiles.append(FileSystem.LoadConfig("debug"))

	Util.Assert(confFiles.size() == Type.COUNT, "Config files count mismatch")

func _post_launch():
	if DisplayServer.get_window_list().size() > 0:
		DisplayServer.window_set_min_size(GetVector2("PresetPC", "minWindowSize", Type.WINDOW), DisplayServer.get_window_list()[0])

	isInitialized = true
	EntityCommons.InitVars()
