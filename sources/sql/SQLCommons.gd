extends Object
class_name SQLCommons

#
const TemplatePath : String				= "sqlite.template.db"
const CurrentDBName : String			= "current.db"
const BackupDBPath : String				= "sql-backups/"
const BackupLimit : int					= 5
const BackupCheckIntervalSec : int		= 2
const BackupIntervalSec : int			= 3600

#
static func HasValue(data : Dictionary, key : String) -> bool:
	return data[key] != null if data.has(key) else false

static func GetOrAddValue(data : Dictionary, key : String, defaultVal : Variant) -> Variant:
	return data[key] if HasValue(data, key) else defaultVal

static func Timestamp() -> int:
	return int(Time.get_unix_time_from_system()) # Remove sub-seconds precision
