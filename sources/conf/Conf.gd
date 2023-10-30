extends ServiceBase


enum Type
{
	NONE = -1,
	PROJECT = 0,
	MAP,
	WINDOW,
	GAMEPLAY,
	NETWORK,
	AUTH,
	DEBUG
}

var confFiles : Array		= []

#
func GetVariant(category : String, param : String, type : int, default):
	var value = default

	if type != Launcher.Conf.Type.NONE\
	&& confFiles[type]\
	&& confFiles[type].has_section_key(category, param):
		value = confFiles[type].get_value(category, param, default)
	else:
		for conf in confFiles:
			if conf && conf.has_section_key(category, param):
				value = conf.get_value(category, param, default)

	return value

func GetBool(category : String, param : String, type : int = Type.NONE) -> bool:
	return GetVariant(category, param, type, false)

func GetInt(category : String, param : String, type : int = Type.NONE) -> int:
	return GetVariant(category, param, type, 0)

func GetFloat(category : String, param : String, type : int = Type.NONE) -> float:
	return GetVariant(category, param, type, 0.0)

func GetVector2(category : String, param : String, type : int = Type.NONE) -> Vector2:
	return GetVariant(category, param, type, Vector2.ZERO)

func GetVector2i(category : String, param : String, type : int = Type.NONE) -> Vector2i:
	return GetVariant(category, param, type, Vector2i.ZERO)

func GetString(category : String, param : String, type : int = Type.NONE) -> String:
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

func _post_launch():
	if DisplayServer.get_window_list().size() > 0:
		DisplayServer.window_set_min_size(GetVector2("PresetPC", "minWindowSize", Type.WINDOW), DisplayServer.get_window_list()[0])

	isInitialized = true
