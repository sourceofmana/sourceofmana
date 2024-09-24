extends ServiceBase
class_name Conf

#
enum Type
{
	NONE = -1,
	SETTINGS = 0,
	USERSETTINGS,
	COUNT
}

static var confFiles : Array		= []
static var cache : Dictionary		= {}

#
static func GetCacheID(section : String, key : String, type : Type) -> String:
	return "%s%s%d" % [section, key, type]

static func GetVariant(section : String, key : String, type : Type, default = null):
	if not confFiles[type] or type >= Type.COUNT:
		assert(false, "Config type is not valid, returning default value")
		return default

	var value = default
	var cacheID = GetCacheID(section, key, type)

	if cacheID in cache:
		value = cache[cacheID]
	elif confFiles[type].has_section_key(section, key):
		value = confFiles[type].get_value(section, key, default)
		cache[cacheID] = value 

	return value

static func GetBool(section : String, key : String, type : Type = Type.NONE) -> bool:
	return GetVariant(section, key, type, false)

static func GetInt(section : String, key : String, type : Type = Type.NONE) -> int:
	return GetVariant(section, key, type, 0)

static func GetFloat(section : String, key : String, type : Type = Type.NONE) -> float:
	return GetVariant(section, key, type, 0.0)

static func GetVector2(section : String, key : String, type : Type = Type.NONE) -> Vector2:
	return GetVariant(section, key, type, Vector2.ZERO)

static func GetVector2i(section : String, key : String, type : Type = Type.NONE) -> Vector2i:
	return GetVariant(section, key, type, Vector2i.ZERO)

static func GetString(section : String, key : String, type : Type = Type.NONE) -> String:
	return GetVariant(section, key, type, "")

static func SetValue(section : String, key : String, type : Type, value):
	assert(type < Type.COUNT and confFiles[type] != null, "Can't find %s within our loaded conf files")
	if type >= Type.COUNT or not confFiles[type]:
		return

	confFiles[type].set_value(section, key, value)
	var cacheID = GetCacheID(section, key, type)
	if cacheID in cache:
		cache[cacheID] = value

static func HasSection(section : String, type : Type) -> bool:
	assert(type < Type.COUNT, "Can't find %s within our loaded conf files")
	return type < Type.COUNT and confFiles[type].has_section(section)

static func HasSectionKey(section : String, key : String, type : Type) -> bool:
	assert(type < Type.COUNT, "Can't find %s within our loaded conf files")
	return type < Type.COUNT and confFiles[type].has_section_key(section, key)

static func SaveType(fileName : String, type : Type):
	assert(type < Type.COUNT, "Can't find %s within our loaded conf files")
	if type < Type.COUNT:
		FileSystem.SaveConfig(fileName, confFiles[type])

#
static func Init():
	confFiles.append(FileSystem.LoadConfig("settings"))
	confFiles.append(FileSystem.LoadConfig("settings", true))

	assert(confFiles.size() == Type.COUNT, "Config files count mismatch")
