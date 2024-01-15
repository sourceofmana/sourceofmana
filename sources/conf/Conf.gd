extends ServiceBase

#
enum Type
{
	NONE = -1,
	PROJECT = 0,
	MAP,
	SETTINGS,
	USERSETTINGS,
	NETWORK,
	AUTH,
	DEBUG,
	COUNT
}

var confFiles : Array		= []
var cache : Dictionary		= {}

#
func GetCacheID(section : String, key : String, type : Type) -> String:
	return "%s%s%d" % [section, key, type]

func GetVariant(section : String, key : String, type : Type, default = null):
	if not confFiles[type] or type >= Type.COUNT:
		return default

	var value = default
	var cacheID = GetCacheID(section, key, type)

	if cacheID in cache:
		value = cache[cacheID]
	elif confFiles[type].has_section_key(section, key):
		value = confFiles[type].get_value(section, key, default)
		cache[cacheID] = value 

	return value

func GetBool(section : String, key : String, type : Type = Type.NONE) -> bool:
	return GetVariant(section, key, type, false)

func GetInt(section : String, key : String, type : Type = Type.NONE) -> int:
	return GetVariant(section, key, type, 0)

func GetFloat(section : String, key : String, type : Type = Type.NONE) -> float:
	return GetVariant(section, key, type, 0.0)

func GetVector2(section : String, key : String, type : Type = Type.NONE) -> Vector2:
	return GetVariant(section, key, type, Vector2.ZERO)

func GetVector2i(section : String, key : String, type : Type = Type.NONE) -> Vector2i:
	return GetVariant(section, key, type, Vector2i.ZERO)

func GetString(section : String, key : String, type : Type = Type.NONE) -> String:
	return GetVariant(section, key, type, "")

func SetValue(section : String, key : String, type : Type, value):
	Util.Assert(type < Type.COUNT and confFiles[type] != null, "Can't find %s within our loaded conf files")
	if type >= Type.COUNT or not confFiles[type]:
		return

	confFiles[type].set_value(section, key, value)
	var cacheID = GetCacheID(section, key, type)
	if cacheID in cache:
		cache[cacheID] = value

func HasSection(section : String, type : Type) -> bool:
	Util.Assert(type < Type.COUNT, "Can't find %s within our loaded conf files")
	return type < Type.COUNT and confFiles[type].has_section(section)

func HasSectionKey(section : String, key : String, type : Type) -> bool:
	Util.Assert(type < Type.COUNT, "Can't find %s within our loaded conf files")
	return type < Type.COUNT and confFiles[type].has_section_key(section, key)

func SaveType(fileName : String, type : Type):
	Util.Assert(type < Type.COUNT, "Can't find %s within our loaded conf files")
	if type < Type.COUNT:
		FileSystem.SaveConfig(fileName, confFiles[type])

#
func _post_launch():
	confFiles.append(FileSystem.LoadConfig("project"))
	confFiles.append(FileSystem.LoadConfig("map"))
	confFiles.append(FileSystem.LoadConfig("settings"))
	confFiles.append(FileSystem.LoadConfig("settings", true))
	confFiles.append(FileSystem.LoadConfig("network"))
	confFiles.append(FileSystem.LoadConfig("auth"))
	confFiles.append(FileSystem.LoadConfig("debug"))

	Util.Assert(confFiles.size() == Type.COUNT, "Config files count mismatch")

	isInitialized = true
	EntityCommons.InitVars()
