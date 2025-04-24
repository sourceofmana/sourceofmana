extends Object
class_name SQLCommons

# Constant variables
const DBNameTemplate : String			= "sqlite.template.db"
const DBNameTesting : String			= "testing.db"
const DBName : String					= "live.db"
const BackupPath : String				= "sql-backups/"
const BackupPathTesting : String		= "sql-testing-backups/"
const BackupLimit : int					= 5
const BackupCheckIntervalSec : int		= 2
const BackupIntervalSec : int			= 60 * 60 * 24 # Every day
const BackupPlayersSec : int			= 10 * 60 # Every minute

# Utils
static func HasValue(data : Dictionary, key : String) -> bool:
	return data[key] != null if data.has(key) else false

static func GetOrAddValue(data : Dictionary, key : String, defaultVal : Variant) -> Variant:
	return data[key] if HasValue(data, key) else defaultVal

static func Timestamp() -> int:
	return int(Time.get_unix_time_from_system()) # Remove sub-seconds precision

# Live/Testing DB handling
static func GetBackupPath() -> String:
	return Path.Local + (BackupPathTesting if LauncherCommons.IsTesting else BackupPath)

static func GetDBPath() -> String:
	return Path.Local + (DBNameTesting if LauncherCommons.IsTesting else DBName)

static func CopyDatabase(targetPath : String) -> bool:
	# Try to copy the live database
	if LauncherCommons.IsTesting:
		var livePath : String = Path.Local + DBName
		if FileSystem.FileExists(livePath):
			var err : Error = DirAccess.copy_absolute(livePath, targetPath)
			assert(err == OK, "Could not copy the database from the source path: " + livePath)
			if err == OK:
				return true

	# Try to copy the template database
	var sourcePath : String = Path.TemplateRsc + DBNameTemplate
	var hasTemplate : bool = FileSystem.FileExists(sourcePath)
	assert(hasTemplate, "Could not copy the database from the source path: " + sourcePath)
	if hasTemplate:
		var err : Error = DirAccess.copy_absolute(sourcePath, targetPath)
		assert(err == OK, "Could not copy the database from the source path: " + sourcePath)
		if err == OK:
			return true

	return false
